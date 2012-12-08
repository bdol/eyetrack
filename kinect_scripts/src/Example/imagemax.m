function J=imagemax(Iin)
d=2;
I=zeros(size(Iin)+d*2);
I((1+d):(end-d),(1+d):(end-d))=Iin;

J=true(size(Iin));
E=zeros(size(Iin)); ek=0;
for x=-d:d
    for y=-d:d
        if((x==0)&&(y==0)), continue; end
        R=I((1+d+x):(end-d+x),(1+d+y):(end-d+y));
        E=E+R; ek=ek+1;
        J(R>Iin)=false;
    end
end
E=E/ek;
J(Iin*0.8<E)=false;
J(Iin<0.3)=false;


