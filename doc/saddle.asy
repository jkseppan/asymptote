import three;
size(100,0);
guide3 g=(1,0,0)..(0,1,1)..(-1,0,0)..(0,-1,1)..cycle3;
filldraw(g,lightgrey);
dot(g,red);
draw(((-1,-1,0)--(1,-1,0)--(1,1,0)--(-1,1,0)--cycle3));
