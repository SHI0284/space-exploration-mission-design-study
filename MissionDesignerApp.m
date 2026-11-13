classdef MissionDesignerApp < handle
    properties
        Figure
        Fields=struct()
        Targets
        Stations
        Map
        Timeline
        Summary
        Events
        CompareTable
        CompareAxes
        Status
        TimeSlider
        RunButton
        AISource
        AIModel
        AIQuestion
        AIOutput
        AIPreview
        AIButton
        AIInfo
        AITab
        AIHistory=cell(0,2)
        AIContext=''
        AILastBody=[]
        Result=[]
        Candidates={}
    end
    methods
        function app=MissionDesignerApp()
            app.Figure=uifigure('Name','OrbitLab | 관측 임무 설계','Position',[60 60 1450 900]);
            app.Figure.Color=[.94 .96 .98];
            app.Figure.UserData=app;
            main=uigridlayout(app.Figure,[3 2]);
            main.RowHeight={62,'1x',34}; main.ColumnWidth={345,'1x'};
            head=uilabel(main,'Text','ORBITLAB   /   관측 임무 설계·비교', ...
                'FontSize',23,'FontWeight','bold','FontColor',[.06 .18 .3]);
            head.Layout.Column=[1 2];
            panel=uipanel(main,'Title','시나리오 설정'); panel.Layout.Row=2;
            left=uigridlayout(panel,[20 2]); left.Scrollable='on';
            left.ColumnWidth={150,'1x'}; left.RowHeight=repmat({28},1,20); left.RowSpacing=6;
            names={'name','epochUTC','durationDays','stepSeconds','model','altitudeKm', ...
                'inclinationDeg','satellites','planes','raanDeg','phaseDeg','fovDeg','minElevationDeg'};
            labels={'시나리오 이름','시작 UTC','분석 기간 (일)','시간 간격 (초)','궤도 모델', ...
                '고도 (km)','경사각 (deg)','위성 수','궤도면 수','기준 RAAN (deg)', ...
                '기준 위상 (deg)','센서 전체 FOV (deg)','지상국 최소 고각 (deg)'};
            c=mission.defaultConfig();
            for k=1:numel(names)
                uilabel(left,'Text',labels{k}); key=names{k};
                if strcmp(key,'model')
                    app.Fields.(key)=uidropdown(left,'Items',{'Two-body','J2 secular'},'Value',c.(key));
                elseif ischar(c.(key))
                    app.Fields.(key)=uieditfield(left,'text','Value',c.(key));
                else
                    app.Fields.(key)=uieditfield(left,'numeric','Value',c.(key));
                end
            end
            app.RunButton=uibutton(left,'Text','분석 실행','BackgroundColor',[.08 .43 .7], ...
                'FontColor',[1 1 1],'FontWeight','bold','ButtonPushedFcn',@(~,~)app.run());
            app.RunButton.Layout.Row=14; app.RunButton.Layout.Column=[1 2];
            b=uibutton(left,'Text','설정 저장','ButtonPushedFcn',@(~,~)app.saveConfig()); b.Layout.Row=15;
            b=uibutton(left,'Text','설정 불러오기','ButtonPushedFcn',@(~,~)app.loadConfig()); b.Layout.Row=15;
            b=uibutton(left,'Text','결과 내보내기','ButtonPushedFcn',@(~,~)app.export()); b.Layout.Row=16;
            b=uibutton(left,'Text','비교 후보에 추가','ButtonPushedFcn',@(~,~)app.addCandidate()); b.Layout.Row=16;
            b=uibutton(left,'Text','3D 보기 (Toolbox)','ButtonPushedFcn',@(~,~)app.viewer());
            b.Layout.Row=17; b.Layout.Column=[1 2];
            note=uilabel(left,'Text',sprintf(['원궤도 · 구형 지구 · 고정 nadir 센서\n' ...
                '대기시간 = 관측 시작 → 같은 위성 접속\n전체 위성 수는 궤도면 수의 배수로 입력']), ...
                'WordWrap','on','FontSize',11,'FontColor',[.35 .42 .5]);
            note.Layout.Row=[18 20]; note.Layout.Column=[1 2];
            tabs=uitabgroup(main); tabs.Layout.Row=2; tabs.Layout.Column=2;
            tab=uitab(tabs,'Title','지도 · 타임라인');
            grid=uigridlayout(tab,[3 1]); grid.RowHeight={'2x',45,'1x'};
            app.Map=uiaxes(grid); app.Map.Layout.Row=1;
            app.TimeSlider=uislider(grid,'Limits',[0 c.durationDays*24],'Value',0, ...
                'ValueChangedFcn',@(~,~)app.updateMap()); app.TimeSlider.Layout.Row=2;
            app.TimeSlider.MajorTicks=linspace(0,c.durationDays*24,7); app.TimeSlider.MinorTicks=[];
            app.Timeline=uiaxes(grid); app.Timeline.Layout.Row=3;
            title(app.Map,'분석 실행 후 궤적과 센서 범위가 표시됩니다');
            tab=uitab(tabs,'Title','관심 지점 · 지상국');
            grid=uigridlayout(tab,[6 2]); grid.RowHeight={30,'1x',30,30,'1x',30};
            l=uilabel(grid,'Text','관심 지점 | 이름, 위도, 경도 (deg)'); l.Layout.Column=[1 2];
            app.Targets=uitable(grid,'Data',c.targets,'ColumnEditable',true(1,3));
            app.Targets.Layout.Row=2; app.Targets.Layout.Column=[1 2];
            b=uibutton(grid,'Text','관심 지점 추가','ButtonPushedFcn',@(~,~)app.addLocation('Targets')); b.Layout.Row=3;
            b=uibutton(grid,'Text','마지막 행 삭제','ButtonPushedFcn',@(~,~)app.removeLocation('Targets')); b.Layout.Row=3;
            l=uilabel(grid,'Text','지상국 | 이름, 위도, 경도 (deg)'); l.Layout.Row=4; l.Layout.Column=[1 2];
            app.Stations=uitable(grid,'Data',c.stations,'ColumnEditable',true(1,3));
            app.Stations.Layout.Row=5; app.Stations.Layout.Column=[1 2];
            b=uibutton(grid,'Text','지상국 추가','ButtonPushedFcn',@(~,~)app.addLocation('Stations')); b.Layout.Row=6;
            b=uibutton(grid,'Text','마지막 행 삭제','ButtonPushedFcn',@(~,~)app.removeLocation('Stations')); b.Layout.Row=6;
            tab=uitab(tabs,'Title','관측 성능 · 전달 대기');
            grid=uigridlayout(tab,[4 1]); grid.RowHeight={48,'1x',35,'2x'};
            uilabel(grid,'Text','최대 공백은 분석 구간 양 끝 포함. 대기 평균·최댓값은 접속 확인 건만 집계합니다.', ...
                'WordWrap','on');
            app.Summary=uitable(grid); app.Summary.Layout.Row=2;
            uilabel(grid,'Text','각 위성-표적 관측 구간 시작에 1회 취득 가정 | NaN = 종료 시점까지 접속 미확인');
            app.Events=uitable(grid); app.Events.Layout.Row=4;
            tab=uitab(tabs,'Title','후보 비교');
            grid=uigridlayout(tab,[4 1]); grid.RowHeight={35,'1x','2x',32};
            uilabel(grid,'Text','같은 기간·지점·시간 간격의 후보만 비교합니다. 설정 변경 후에는 다시 분석하세요.');
            app.CompareTable=uitable(grid); app.CompareTable.Layout.Row=2;
            app.CompareAxes=uiaxes(grid); app.CompareAxes.Layout.Row=3;
            b=uibutton(grid,'Text','비교 후보 초기화','ButtonPushedFcn',@(~,~)app.clearCandidates()); b.Layout.Row=4;
            app.AITab=uitab(tabs,'Title','AI 결과 해석');
            grid=uigridlayout(app.AITab,[7 1]); grid.RowHeight={42,36,60,38,'2x',28,'1x'};
            uilabel(grid,'Text','현재 결과를 근거로 설명·비교·후속 실험을 질문하세요. 요청 시 아래 근거와 최근 대화 3쌍을 OpenAI로 보냅니다.', ...
                'WordWrap','on');
            controls=uigridlayout(grid,[1 4]); controls.Layout.Row=2;
            controls.ColumnWidth={'1x','1x',110,110};controls.Padding=[0 0 0 0];
            app.AISource=uidropdown(controls,'Items',{'현재 관측 결과','고정 태양 식 실습','Toolbox 조명 실습','Walker 위성군 실습'}, ...
                'ValueChangedFcn',@(~,~)app.resetAI());
            model=getenv('OPENAI_MODEL');if isempty(model),model='gpt-4.1-mini';end
            app.AIModel=uieditfield(controls,'text','Value',model,'Tooltip','OpenAI Responses API 모델 ID');
            uibutton(controls,'Text','API 키 등록','ButtonPushedFcn',@(~,~)app.configureAI());
            uibutton(controls,'Text','근거 미리보기','ButtonPushedFcn',@(~,~)app.previewAI());
            app.AIQuestion=uitextarea(grid,'Value',{'이번 결과의 핵심을 요약하고, 확인된 사실과 가능한 원인을 구분해서 설명해줘. 다음에 해볼 실험도 제안해줘.'});
            app.AIQuestion.Layout.Row=3;
            actions=uigridlayout(grid,[1 3]);actions.Layout.Row=4;actions.Padding=[0 0 0 0];
            app.AIButton=uibutton(actions,'Text','AI에게 질문','BackgroundColor',[.08 .43 .7], ...
                'FontColor',[1 1 1],'ButtonPushedFcn',@(~,~)app.askAI());
            uibutton(actions,'Text','대화 초기화','ButtonPushedFcn',@(~,~)app.resetAI());
            uibutton(actions,'Text','해석 저장','ButtonPushedFcn',@(~,~)app.saveAI());
            app.AIOutput=uitextarea(grid,'Editable','off','Value',{'아직 AI에 요청하지 않았습니다. 분석 결과를 준비한 뒤 질문하세요.'});
            app.AIOutput.Layout.Row=5;
            app.AIInfo=uilabel(grid,'Text','API 키는 MATLAB 세션에만 등록됩니다. 질문할 때 API 사용 요금이 발생할 수 있습니다.');
            app.AIInfo.Layout.Row=6;
            app.AIPreview=uitextarea(grid,'Editable','off','Value',{'전송할 근거 데이터: 미리보기 버튼으로 확인할 수 있습니다.'});
            app.AIPreview.Layout.Row=7;
            app.Status=uilabel(main,'Text','준비됨 · 기본 시나리오: 서울 / 부산 / 제주, 대전 지상국', ...
                'FontColor',[.2 .35 .45]); app.Status.Layout.Row=3; app.Status.Layout.Column=[1 2];
        end
        function c=getConfig(app)
            c=mission.defaultConfig(); names=fieldnames(app.Fields);
            for k=1:numel(names), c.(names{k})=app.Fields.(names{k}).Value; end
            c.targets=app.Targets.Data; c.stations=app.Stations.Data;
            c=mission.validateConfig(c);
        end
        function setConfig(app,c)
            c=mission.validateConfig(c); names=fieldnames(app.Fields);
            for k=1:numel(names), app.Fields.(names{k}).Value=c.(names{k}); end
            app.Targets.Data=c.targets; app.Stations.Data=c.stations;
            app.Status.Text='설정을 불러왔습니다. 분석 실행을 눌러 결과를 갱신하세요.';
        end
        function run(app)
            app.RunButton.Enable='off'; cleanup=onCleanup(@()set(app.RunButton,'Enable','on')); %#ok<NASGU>
            try
                c=app.getConfig(); app.Status.Text='궤도 전파 및 관측·지상국 접속 계산 중...'; drawnow;
                r=mission.analyze(c); app.Result=r;
                app.resetAI();
                app.TimeSlider.Limits=[0 c.durationDays*24]; app.TimeSlider.Value=0;
                app.TimeSlider.MajorTicks=linspace(0,c.durationDays*24,7);
                mission.drawMap(app.Map,r,0); mission.drawTimeline(app.Timeline,r);
                app.Summary.Data=r.summary; app.Events.Data=r.events;
                app.Status.Text=sprintf('%s | 완료: 관측 %d건 · 접속 미확인 %d건 | 지도 슬라이더: 경과 시간(h)', ...
                    c.name,height(r.events),sum(~r.events.Resolved));
            catch e
                app.fail(e);
            end
        end
        function updateMap(app)
            if ~isempty(app.Result), mission.drawMap(app.Map,app.Result,app.TimeSlider.Value*3600); end
        end
        function addLocation(app,key)
            T=app.(key).Data; name=sprintf('Point_%d',height(T)+1);
            while any(string(T.Name)==string(name)), name=[name '_new']; end %#ok<AGROW>
            T(end+1,:)={name,36,127}; app.(key).Data=T;
        end
        function removeLocation(app,key)
            T=app.(key).Data; if height(T)>1, T(end,:)=[]; app.(key).Data=T; end
        end
        function saveConfig(app)
            try
                config=app.getConfig(); [f,p]=uiputfile('*.mat','시나리오 저장','scenario.mat');
                if isequal(f,0), return; end
                save(fullfile(p,f),'config'); app.Status.Text='시나리오 저장 완료';
            catch e, app.fail(e); end
        end
        function loadConfig(app)
            try
                [f,p]=uigetfile('*.mat','시나리오 불러오기'); if isequal(f,0), return; end
                x=load(fullfile(p,f),'config'); app.setConfig(x.config);
            catch e, app.fail(e); end
        end
        function requireCurrent(app)
            assert(~isempty(app.Result),'먼저 분석을 실행하세요.');
            assert(isequaln(app.Result.config,app.getConfig()),'설정이 변경되었습니다. 다시 분석하세요.');
        end
        function export(app)
            try
                app.requireCurrent(); p=uigetdir(pwd,'결과를 저장할 상위 폴더'); if isequal(p,0), return; end
                folder=tempname(p); mkdir(folder);
                mission.exportResult(app.Result,folder);
                if ~isempty(app.Candidates)
                    writetable(app.CompareTable.Data,fullfile(folder,'comparison.csv'));
                    candidateConfigs=cellfun(@(r)r.config,app.Candidates,'UniformOutput',false); %#ok<NASGU>
                    save(fullfile(folder,'comparison_scenarios.mat'),'candidateConfigs');
                end
                app.Status.Text=['결과 저장 완료: ' folder];
            catch e, app.fail(e); end
        end
        function addCandidate(app)
            try
                app.requireCurrent(); c=app.Result.config;
                if ~isempty(app.Candidates)
                    base=app.Candidates{1}.config;
                    keys={'epochUTC','durationDays','stepSeconds','targets','stations'};
                    for k=1:numel(keys)
                        assert(isequaln(c.(keys{k}),base.(keys{k})), ...
                            '비교 기간·지점·시간 간격이 다릅니다. 비교 후보를 초기화하거나 조건을 맞추세요.');
                    end
                    for k=1:numel(app.Candidates)
                        assert(~strcmp(c.name,app.Candidates{k}.config.name),'다른 후보 이름을 입력하고 다시 분석하세요.');
                    end
                end
                app.Candidates{end+1}=app.Result; rows=cell(numel(app.Candidates),7);
                for k=1:numel(app.Candidates)
                    r=app.Candidates{k}; w=r.events.WaitSeconds; w=w(isfinite(w)); avg=NaN;
                    if ~isempty(w), avg=mean(w)/60; end
                    rows(k,:)={string(r.config.name),r.config.satellites,r.config.fovDeg, ...
                        max(r.summary.MaxGapHours),height(r.events),avg,sum(~r.events.Resolved)};
                end
                T=cell2table(rows,'VariableNames',{'Candidate','Satellites','FOVDeg','WorstGapHours', ...
                    'Acquisitions','MeanResolvedWaitMinutes','Unresolved'});
                app.CompareTable.Data=T; cla(app.CompareAxes);
                bar(app.CompareAxes,T.WorstGapHours,'FaceColor',[.1 .5 .75]);
                app.CompareAxes.XTick=1:height(T); app.CompareAxes.XTickLabel=T.Candidate;
                ylabel(app.CompareAxes,'Worst target gap (hours)'); grid(app.CompareAxes,'on');
                app.Status.Text='현재 분석 결과를 비교 후보에 추가했습니다.';
            catch e, app.fail(e); end
        end
        function clearCandidates(app)
            app.Candidates={}; app.CompareTable.Data=[]; cla(app.CompareAxes);
        end
        function viewer(app)
            try
                app.requireCurrent(); mission.openViewer(app.Result);
            catch e, app.fail(e); end
        end
        function evidence=getAIEvidence(app)
            root=fileparts(mfilename('fullpath'));
            switch app.AISource.Value
                case 'Walker 위성군 실습'
                    path=fullfile(root,'results','walker','result.mat');
                    assert(isfile(path),'먼저 run_walker_demo를 실행하세요.');
                    x=load(path,'result'); evidence=mission.aiEvidence(x.result);
                case '현재 관측 결과'
                    app.requireCurrent(); evidence=mission.aiEvidence(app.Result,app.Candidates);
                case '고정 태양 식 실습'
                    path=fullfile(root,'results','shadow_geometry','result.mat');
                    assert(isfile(path),'먼저 run_shadow_geometry_demo를 실행하세요.');
                    x=load(path,'result'); evidence=mission.aiEvidence(x.result);
                case 'Toolbox 조명 실습'
                    path=fullfile(root,'results','lighting','lighting_result.mat');
                    assert(isfile(path),'공식 조명 결과가 없습니다. Ephemeris Data 설치 후 run_lighting_demo를 실행하세요.');
                    x=load(path,'result'); evidence=mission.aiEvidence(x.result);
            end
        end
        function previewAI(app)
            try
                evidence=app.getAIEvidence(); app.AIPreview.Value=splitlines(string(jsonencode(evidence,'PrettyPrint',true)));
            catch e,app.fail(e);end
        end
        function configureAI(app)
            try
                if configure_openai_key(),app.AIInfo.Text='API 키 등록됨 · 현재 MATLAB 세션에서만 사용합니다.';end
            catch e,app.fail(e);end
        end
        function resetAI(app)
            app.AIHistory=cell(0,2);app.AIContext='';app.AILastBody=[];
            if ~isempty(app.AIOutput)
                app.AIOutput.Value={'아직 AI에 요청하지 않았습니다. 현재 결과에 대해 질문하세요.'};
                app.AIPreview.Value={'전송할 근거 데이터: 미리보기 버튼으로 확인할 수 있습니다.'};
            end
        end
        function askAI(app)
            app.AIButton.Enable='off'; cleanup=onCleanup(@()set(app.AIButton,'Enable','on')); %#ok<NASGU>
            try
                evidence=app.getAIEvidence(); context=jsonencode(evidence);
                if ~strcmp(context,app.AIContext)
                    app.AIHistory=cell(0,2);app.AIContext=context;app.AILastBody=[];
                    app.AIOutput.Value={'현재 근거에 대해 AI 응답을 기다리는 중입니다.'};
                end
                app.AIPreview.Value=splitlines(string(jsonencode(evidence,'PrettyPrint',true)));
                question=char(strjoin(string(app.AIQuestion.Value),newline));
                app.AIInfo.Text='AI 응답 요청 중… 최대 90초 정도 기다릴 수 있습니다.';drawnow;
                [answer,meta,body]=mission.askAI(evidence,question,app.AIHistory,app.AIModel.Value);
                app.AIHistory(end+1,:)={question,answer};app.AILastBody=body;
                transcript={};
                for k=1:size(app.AIHistory,1)
                    transcript=[transcript;{['질문: ' app.AIHistory{k,1}];app.AIHistory{k,2};'──────────'}]; %#ok<AGROW>
                end
                app.AIOutput.Value=splitlines(strjoin(string(transcript),newline));
                app.AIInfo.Text=['응답 완료 · ' char(meta.model) ' · AI의 해석은 계산 근거와 함께 확인하세요.'];
            catch e
                app.AIInfo.Text=['요청 실패: ' e.message]; app.fail(e);
            end
        end
        function saveAI(app)
            try
                assert(~isempty(app.AILastBody),'먼저 AI 답변을 받아야 합니다.');
                [f,p]=uiputfile('*.txt','AI 해석 저장','ai-analysis.txt');if isequal(f,0),return;end
                fid=fopen(fullfile(p,f),'w','n','UTF-8');assert(fid>=0,'파일을 열 수 없습니다.');
                cleanup=onCleanup(@()fclose(fid)); %#ok<NASGU>
                fprintf(fid,'OrbitLab AI interpretation\nModel: %s\n\n%s\n\nEvidence snapshot:\n%s\n', ...
                    app.AILastBody.model,strjoin(string(app.AIOutput.Value),newline),app.AIContext);
                app.AIInfo.Text='AI 해석과 사용한 근거를 저장했습니다.';
            catch e,app.fail(e);end
        end
        function fail(app,e)
            app.Status.Text=['오류: ' e.message]; uialert(app.Figure,e.message,'입력 또는 실행 오류');
        end
    end
end
