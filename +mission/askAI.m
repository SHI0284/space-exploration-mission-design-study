function [answer,meta,body]=askAI(evidence,question,history,model)
% Key exists only in request memory; never in configuration, exports, or errors.
key=strtrim(getenv('OPENAI_API_KEY'));
assert(~isempty(key),'mission:AIKeyMissing', ...
    'OPENAI_API_KEY 환경변수가 없습니다. AI_SETUP.md를 참고해 등록하고 MATLAB을 다시 시작하세요. 키를 채팅에 붙여넣지 마세요.');
body=mission.aiRequest(evidence,question,history,model);
headers=[matlab.net.http.HeaderField('Content-Type','application/json'), ...
    matlab.net.http.HeaderField('Authorization',['Bearer ' key])];
request=matlab.net.http.RequestMessage('post',headers,matlab.net.http.MessageBody(jsonencode(body)));
options=matlab.net.http.HTTPOptions('ConnectTimeout',15,'ResponseTimeout',90,'MaxRedirects',0);
try
    response=request.send('https://api.openai.com/v1/responses',options);
catch
    error('mission:AINetwork','AI 서버에 연결하지 못했습니다. 인터넷 연결을 확인하세요. 자동 재시도는 하지 않았습니다.');
end
code=double(response.StatusCode);
if code~=200
    switch code
        case 401,msg='API 키 인증에 실패했습니다. OPENAI_API_KEY를 확인하세요.';
        case 403,msg='이 API 또는 모델에 대한 계정 접근 권한을 확인하세요.';
        case 404,msg='모델을 찾을 수 없습니다. 사용 가능한 모델 ID를 입력하세요.';
        case 429,msg='호출 한도 또는 API 잔액을 확인하세요. 잠시 후 직접 재시도하세요.';
        case 400,msg='요청 설정이 지원되지 않습니다. 모델 ID와 입력 길이를 확인하세요.';
        otherwise,msg=sprintf('AI 서버 응답 오류 (HTTP %d). 잠시 후 직접 재시도하세요.',code);
    end
    error('mission:AIHTTP','%s',msg);
end
data=response.Body.Data;
if ischar(data)||isstring(data),data=jsondecode(data);end
[answer,meta]=mission.aiResponseText(data);
end
