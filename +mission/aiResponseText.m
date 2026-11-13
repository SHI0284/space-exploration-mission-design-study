function [answer,meta]=aiResponseText(response)
% Raw HTTP response output can contain heterogeneous items (cell arrays).
parts={}; refused=false;
assert(isstruct(response)&&isfield(response,'output'),'mission:AIResponse','AI 응답 형식을 확인할 수 없습니다.');
items=response.output;if ~iscell(items),items=num2cell(items);end
for k=1:numel(items)
    item=items{k};
    if ~isfield(item,'type')||~strcmp(item.type,'message')||~isfield(item,'content'),continue;end
    content=item.content;if ~iscell(content),content=num2cell(content);end
    for j=1:numel(content)
        v=content{j};
        if strcmp(v.type,'output_text'),parts{end+1}=char(v.text);end %#ok<AGROW>
        if strcmp(v.type,'refusal'),refused=true;end
    end
end
if refused,error('mission:AIRefusal','AI가 이 요청에 답변하지 않았습니다. 질문을 바꿔보세요.');end
answer=strjoin(parts,newline);
assert(~isempty(strtrim(answer)),'mission:AIResponse','AI가 설명 텍스트를 반환하지 않았습니다.');
meta=struct('incomplete',false,'model','','usage',struct());
if isfield(response,'status'),meta.incomplete=strcmp(response.status,'incomplete');end
if isfield(response,'model'),meta.model=response.model;end
if isfield(response,'usage'),meta.usage=response.usage;end
if meta.incomplete,answer=[answer newline newline '[출력 한도 등으로 답변이 중간에 끝났습니다. 질문 범위를 줄여 다시 요청하세요.]'];end
end
