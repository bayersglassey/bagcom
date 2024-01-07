#!/bin/bash
set -euo pipefail

cfile="$1"
binfile="$2"
shift 2

code="$(cat -)"

echo "
#include \"stdio.h\"
#include \"stdlib.h\"
typedef unsigned int I;
int main(int n_args, char **args){
    I t_max = 0;
    if (n_args >= 2) t_max = atoi(args[1]);
    for(I t=0; !t_max || t < t_max; t++){
        I a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,u,v,w,x,y,z;
        unsigned char _c = (c=0, ($code));
        unsigned char _c2 = (c=1, ($code));
        putchar(_c);
        putchar(_c2);
    }
    return 0;
}" >"$cfile"

gcc "$cfile" -o "$binfile"
