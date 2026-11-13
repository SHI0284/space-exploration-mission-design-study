function [wait,contact] = nextContact(observed, I)
% I is the same satellite's union of ground-station contacts [start,end).
wait=nan(size(observed)); contact=wait;
for k=1:numel(observed)
    j=find(I(:,2)>observed(k),1);
    if ~isempty(j)
        contact(k)=max(observed(k),I(j,1));
        wait(k)=contact(k)-observed(k);
    end
end
end
