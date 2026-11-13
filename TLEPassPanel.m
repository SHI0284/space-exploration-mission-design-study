classdef TLEPassPanel < handle
    properties
        Parent
        Fields=struct()
        Catalog
        Input
        Info
        Table
        Choice
        Sky
        Profile
        RunButton
        Result=[]
        LoadedTLE=[]
    end
    methods
        function app=TLEPassPanel(parent)
            app.Parent=parent;c=mission.tleConfig();
            g=uigridlayout(parent,[9 1]);g.RowHeight={30,34,65,54,34,54,'1x',30,'1.6x'};g.RowSpacing=5;
            uilabel(g,'Text','실제 TLE · 국제캠퍼스 기준 24시간 기하학적 교신 후보 | 하늘 경로는 육안 관측 가능성과 다릅니다.','WordWrap','on');
            row=uigridlayout(g,[1 6]);row.Layout.Row=2;row.Padding=[0 0 0 0];row.ColumnWidth={90,85,150,110,110,'1x'};
            uilabel(row,'Text','NORAD 번호');app.Catalog=uieditfield(row,'numeric','Value',25544,'Limits',[1 99999],'RoundFractionalValues','on','ValueDisplayFormat','%.0f');
            uibutton(row,'Text','CelesTrak TLE 받기','ButtonPushedFcn',@(~,~)app.fetch());
            uibutton(row,'Text','TLE 파일 열기','ButtonPushedFcn',@(~,~)app.loadFile());
            uibutton(row,'Text','단계별 실습','ButtonPushedFcn',@(~,~)edit(fullfile(fileparts(mfilename('fullpath')),'study_tle.m')));
            uilabel(row,'Text','ISS 25544 · 2시간 캐시','WordWrap','on');
            app.Input=uitextarea(g,'Value',{'TLE를 받거나 한 위성의 TLE 2줄/3줄을 붙여넣으세요.'},'FontName','Consolas','ValueChangedFcn',@(~,~)app.invalidate());app.Input.Layout.Row=3;
            row=uigridlayout(g,[2 5]);row.Layout.Row=4;row.Padding=[0 0 0 0];row.RowHeight={20,28};
            labels={'위도 (deg)','경도 (deg)','타원체고 (m, 가정)','최소 고각 (deg)','표본 간격 (s)'};
            keys={'latitudeDeg','longitudeDeg','altitudeM','minElevationDeg','stepSeconds'};
            for k=1:5
                l=uilabel(row,'Text',labels{k});l.Layout.Row=1;l.Layout.Column=k;
                f=uieditfield(row,'numeric','Value',c.(keys{k}),'ValueChangedFcn',@(~,~)app.invalidate());
                if k<=2,f.ValueDisplayFormat='%.6f';else,f.ValueDisplayFormat='%.1f';end
                f.Layout.Row=2;f.Layout.Column=k;app.Fields.(keys{k})=f;
            end
            row=uigridlayout(g,[1 5]);row.Layout.Row=5;row.Padding=[0 0 0 0];row.ColumnWidth={100,'1x',90,130,110};
            uilabel(row,'Text','시작 KST');app.Fields.startKST=uieditfield(row,'text','Value',c.startKST,'ValueChangedFcn',@(~,~)app.invalidate());
            uibutton(row,'Text','현재 시각','ButtonPushedFcn',@(~,~)app.setNow());
            app.RunButton=uibutton(row,'Text','24시간 예측','ButtonPushedFcn',@(~,~)app.run(),'BackgroundColor',[.08 .43 .7],'FontColor',[1 1 1]);
            uibutton(row,'Text','결과 저장','ButtonPushedFcn',@(~,~)app.export());
            app.Info=uilabel(g,'Text','국제캠퍼스의 학습용 근삿값입니다. 실제 안테나 좌표·고도로 수정할 수 있습니다. 지형·건물·링크버짓 미반영.', ...
                'WordWrap','on','FontSize',11);app.Info.Layout.Row=6;
            app.Table=uitable(g,'CellSelectionCallback',@(~,e)app.selectRow(e));app.Table.Layout.Row=7;
            app.Choice=uidropdown(g,'Items',{'패스를 선택하세요'},'Enable','off','ValueChangedFcn',@(~,~)app.draw());app.Choice.Layout.Row=8;
            row=uigridlayout(g,[1 2]);row.Layout.Row=9;row.Padding=[0 0 0 0];
            app.Sky=polaraxes(row);app.Sky.Layout.Column=1;
            app.Profile=uiaxes(row);app.Profile.Layout.Column=2;
        end
        function c=config(app)
            c=mission.tleConfig();keys=fieldnames(app.Fields);
            for k=1:numel(keys),c.(keys{k})=app.Fields.(keys{k}).Value;end
        end
        function invalidate(app)
            app.Result=[];app.Table.Data=[];app.Choice.Enable='off';
            cla(app.Sky);cla(app.Profile);app.Info.Text='입력이 변경되었습니다. 24시간 예측을 다시 실행하세요.';
        end
        function setNow(app)
            c=mission.tleConfig();app.Fields.startKST.Value=c.startKST;app.invalidate();
        end
        function fetch(app)
            app.Info.Text='CelesTrak TLE 확인 중…';drawnow;
            try
                tle=mission.fetchTLE(app.Catalog.Value);app.setTLE(tle);
            catch e,app.fail(e);end
        end
        function setTLE(app,tle)
            app.invalidate();app.LoadedTLE=tle;app.Input.Value=splitlines(string(tle.text));
            app.Catalog.Value=tle.catalogNumber;
            suffix='';if tle.fromCache,suffix=' · 2시간 이내 캐시';end
            app.Info.Text=sprintf('%s | TLE epoch %s UTC%s | 24시간 예측을 실행하세요.',tle.name,string(tle.epochUTC,'yyyy-MM-dd HH:mm:ss'),suffix);
        end
        function loadFile(app)
            [f,p]=uigetfile({'*.tle;*.txt','TLE file'},'한 위성의 TLE 파일');if isequal(f,0),return;end
            try,tle=mission.parseTLE(fileread(fullfile(p,f)));tle.source='Local TLE file';app.setTLE(tle);
            catch e,app.fail(e);end
        end
        function tle=currentTLE(app)
            tle=mission.parseTLE(app.Input.Value);
            if ~isempty(app.LoadedTLE)&&strcmp(tle.text,app.LoadedTLE.text),tle=app.LoadedTLE;end
        end
        function run(app)
            app.RunButton.Enable='off';cleanup=onCleanup(@()set(app.RunButton,'Enable','on')); %#ok<NASGU>
            try
                tle=app.currentTLE();c=app.config();app.invalidate();
                app.Info.Text='TLE 전파 및 24시간 고각·접속 계산 중…';drawnow;
                r=mission.analyzeTLE(tle,c);app.Result=r;
                T=r.schedule;view=T(:,1:11);
                for key={'StartKST','EndKST','PeakKST'},view.(key{1})=string(view.(key{1}),'MM-dd HH:mm:ss');end
                app.Table.Data=view;app.Table.ColumnName={'패스','시작 KST','종료 KST','최대고각 KST','분','최대고각°','시작방위°','종료방위°','최대고각 거리 km','시작 잘림','종료 잘림'};
                if height(T)>0
                    app.Choice.Items=cellstr(compose('#%d | %s KST | %.1f°',T.Pass,string(T.StartKST,'MM-dd HH:mm:ss'),T.MaxElevationDeg));
                    app.Choice.ItemsData=1:height(T);app.Choice.Value=1;app.Choice.Enable='on';
                else
                    app.Choice.ItemsData=[];app.Choice.Items={'패스 없음'};app.Choice.Enable='off';
                end
                app.draw();
                received='파일/직접 입력';
                if ~isnat(tle.retrievedUTC),received=char(string(tle.retrievedUTC,'MM-dd HH:mm')+' UTC');end
                app.Info.Text=sprintf('%s | %d개 후보 | TLE epoch %s UTC | 시작 기준 나이 %.1f시간\n가져온 시각: %s · 근사 좌표/타원체고 %.0f m | %s', ...
                    tle.name,height(T),string(tle.epochUTC,'yyyy-MM-dd HH:mm:ss'),r.tleAgeStartHours,received,c.altitudeM,r.notes{end});
            catch e,app.fail(e);end
        end
        function r=getCurrent(app)
            assert(~isempty(app.Result),'먼저 TLE 24시간 예측을 실행하세요.');
            tle=app.currentTLE();assert(isequaln(app.Result.settings,app.config())&&strcmp(tle.text,app.Result.tle.text), ...
                'TLE 또는 지상국 설정이 변경되었습니다. 다시 예측하세요.');r=app.Result;
        end
        function selectRow(app,e)
            if isempty(app.Result)||isempty(e.Indices)||isempty(app.Result.tracks),return;end
            app.Choice.Value=e.Indices(1,1);app.draw();
        end
        function draw(app)
            if isempty(app.Result),return;end
            index=1;if ~isempty(app.Result.tracks),index=app.Choice.Value;end
            mission.drawTLEPass(app.Sky,app.Profile,app.Result,index);
        end
        function export(app)
            try
                r=app.getCurrent();p=uigetdir(pwd,'저장할 상위 폴더');if isequal(p,0),return;end
                folder=tempname(p);mission.exportTLE(r,folder);
                exportgraphics(app.Sky,fullfile(folder,'selected_sky_track.png'),'Resolution',150);
                app.Info.Text=['저장 완료: ' folder];
            catch e,app.fail(e);end
        end
        function fail(app,e)
            app.Info.Text=e.message;uialert(ancestor(app.Parent,'figure'),e.message,'TLE 예측 오류');
        end
    end
end
