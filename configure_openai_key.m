function configured=configure_openai_key()
% Masked desktop prompt. Stores key only in this MATLAB process environment.
assert(usejava('desktop'),'MATLAB 데스크톱에서 실행하거나 OPENAI_API_KEY 환경변수를 설정하세요.');
field=javaObjectEDT('javax.swing.JPasswordField',40);
cleanup=onCleanup(@()field.setText('')); %#ok<NASGU>
choice=javax.swing.JOptionPane.showConfirmDialog([],field, ...
    'OpenAI API key - MATLAB session only',int32(2),int32(3));
configured=false;
if choice~=0,return;end
key=strtrim(char(field.getPassword()));
assert(~isempty(key),'빈 키는 등록할 수 없습니다.');
setenv('OPENAI_API_KEY',key); configured=true;
end
