function tests=test_ai
tests=functiontests(localfunctions);
end
function setupOnce(tc)
root=fileparts(fileparts(mfilename('fullpath')));addpath(root);
c=mission.defaultConfig();c.durationDays=.25;
tc.TestData.r=mission.analyze(c);tc.TestData.root=root;
end
function testEvidenceAllowlist(tc)
r=tc.TestData.r;r.config.apiKey='DO_NOT_EXPORT';r.secret='DO_NOT_EXPORT';
e=mission.aiEvidence(r,{r}); j=jsonencode(e);
verifyFalse(tc,contains(j,'DO_NOT_EXPORT'));
verifyFalse(tc,isfield(e.current,'positionECEFKm'));
verifyEqual(tc,e.current.eventCount,height(r.events));
verifyEqual(tc,e.current.unresolvedCount,sum(~r.events.Resolved));
verifyEqual(tc,e.current.longestGaps{1}.hours,r.summary.MaxGapHours(1),'AbsTol',1e-10);
verifyEqual(tc,e.comparisonIncluded,1);
end
function testCensoredNoAccess(tc)
c=mission.defaultConfig();c.durationDays=.1;c.inclinationDeg=0;
c.targets=table({'Pole'},90,0,'VariableNames',c.targets.Properties.VariableNames);
e=mission.aiEvidence(mission.analyze(c));
verifyEqual(tc,e.current.eventCount,0);
verifyEqual(tc,e.current.longestGaps{1}.hours,2.4,'AbsTol',1e-10);
verifyTrue(tc,isnan(e.current.meanResolvedWaitMinutes));
verifyTrue(tc,contains(jsonencode(e),'null'));
end
function testRequestContract(tc)
e=mission.aiEvidence(tc.TestData.r);h={'q1','a1';'q2','a2';'q3','a3';'q4','a4'};
b=mission.aiRequest(e,'왜 대기시간이 0인가?',h,'gpt-4.1-mini');
j=jsondecode(jsonencode(b));
verifyFalse(tc,j.store);verifyEqual(tc,numel(b.input),8);
verifyEqual(tc,b.input{2}.content,'q2');
verifyEqual(tc,b.input{end}.content,'왜 대기시간이 0인가?');
verifyFalse(tc,isfield(b,'previous_response_id'));
verifyError(tc,@()mission.aiRequest(e,'',h,'gpt-4.1-mini'),'mission:AIInput');
end
function testResponseMixedItems(tc)
r=struct('output',{{struct('type','reasoning'),struct('type','message','content', ...
    {{struct('type','output_text','text','근거 설명'),struct('type','output_text','text','추가 해석')}})}}, ...
    'status','completed','model','test');
[a,m]=mission.aiResponseText(r);verifyTrue(tc,contains(a,'근거 설명'));verifyFalse(tc,m.incomplete);
r.status='incomplete';[a,m]=mission.aiResponseText(r);verifyTrue(tc,m.incomplete);verifyTrue(tc,contains(a,'중간에'));
end
function testRefusal(tc)
r=struct('output',struct('type','message','content',struct('type','refusal','refusal','no')));
verifyError(tc,@()mission.aiResponseText(r),'mission:AIRefusal');
end
function testMissingKeyNoNetwork(tc)
old=getenv('OPENAI_API_KEY');cleanup=onCleanup(@()setenv('OPENAI_API_KEY',old)); %#ok<NASGU>
setenv('OPENAI_API_KEY','');
verifyError(tc,@()mission.askAI(struct(),'q',{},'test'),'mission:AIKeyMissing');
end
function testHTTPConfiguration(tc)
o=matlab.net.http.HTTPOptions('ConnectTimeout',15,'ResponseTimeout',90,'MaxRedirects',0);
verifyEqual(tc,o.MaxRedirects,0);
b=mission.aiRequest(mission.aiEvidence(tc.TestData.r),'요약해줘',{},'gpt-4.1-mini');
req=matlab.net.http.RequestMessage('post',matlab.net.http.HeaderField('Content-Type','application/json'), ...
    matlab.net.http.MessageBody(jsonencode(b)));
verifyTrue(tc,contains(string(req.Body.Data),'요약해줘'));
end
function testShadowEvidence(tc)
% This fixture tests serialization, not the numerical shadow model.
r=struct('assumption','Fixed Sun on +ICRF X','history',table(), ...
    'summary',table(35.5,'VariableNames',{'SampledCylinderMinutes'}), ...
    'intervals',table(0,60,'VariableNames',{'StartSeconds','EndSeconds'}));
e=mission.aiEvidence(r);verifyEqual(tc,e.kind,'fixed-sun-shadow-study');
verifyTrue(tc,contains(jsonencode(e),'NOT official eclipse'));
end
