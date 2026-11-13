function I = intervals(t,status)
% Left-held samples define [t(i),t(i+1)); final endpoint has no duration.
t=t(:); status=logical(status(:));
assert(numel(t)==numel(status)&&numel(t)>=2&&all(diff(t)>0));
b=status(1:end-1);
edges=diff([false;b;false]);
I=[t(find(edges==1)),t(find(edges==-1))];
end
