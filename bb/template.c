
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>

#define MODES "bsS"

typedef unsigned int uint;


void prog(FILE *file, uint t0, uint t1, char mode) {
    if (mode == 'b') {
        do for(uint t=t0; t < t1; t++){
            uint a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,u,v,w,x,y,z;
            unsigned char _c = (c=0, PROG);
            putchar(_c);
            #if CHANS >= 2
            unsigned char _c2 = (c=1, PROG);
            putchar(_c2);
            #endif
        } while(!t1);
    } else if (mode == 's') {
        do for(uint t=t0; t < t1; t++){
            uint a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,u,v,w,x,y,z;
            unsigned char _c = (c=0, PROG);
            printf("%i,%i\n", t - t0, 256 - _c);
        } while(!t1);
    #if CHANS >= 2
    } else if (mode == 't') {
        do for(uint t=t0; t < t1; t++){
            uint a,b,c,d,e,f,g,h,i,j,k,l,m,n,o,p,q,r,s,u,v,w,x,y,z;
            unsigned char _c2 = (c=0, PROG);
            printf("%i,%i\n", t - t0, 512 - _c2);
        } while(!t1);
    #endif
    } else {
        fprintf(stderr, "Unrecognized mode: [%c]\n", mode);
        exit(1);
    }
}


void print_svg(FILE *file, uint t0, uint t1, bool fullpage) {
    int container_h = fullpage? 320: 200;
    uint w = t1 - t0;
    uint h = 256 * CHANS;
    if (fullpage) {
        fprintf(file,
            "<html>\n"
            "<head>\n"
        );
        FILE *header_file = fopen("bb/header.html", "r");
        if (!header_file) {
            perror("fopen bb/header.html");
            exit(1);
        }
        char buf[1024 * 8];
        size_t len = fread(buf, 1, sizeof buf, header_file);
        fwrite(buf, 1, len, file);
        fclose(header_file);
        fprintf(file,
            "</head>\n"
            "<body>\n"
        );
    }
    fprintf(file,
        "<div class=\"svg-container\"\n"
        "    style=\"height: %ipx;\"\n"
        "    data-zoom-on-wheel=\"max-scale: 500;\"\n"
        "    data-pan-on-drag\n"
        ">\n"
        "    <svg\n"
        "        viewBox=\"0 0 %u %u\"\n"
        "        preserveAspectRatio=\"xMidYMid meet\"\n"
        "        version=\"1.1\" xmlns=\"http://www.w3.org/2000/svg\"\n"
        "    >\n"
        "        <style>\n"
        "            .t-marker { font: 13px sans-serif; fill: grey; }\n"
        "        </style>\n"
        "        <rect x=\"0\" y=\"0\" width=\"%u\" height=\"256\" stroke=\"grey\" fill=\"transparent\" stroke-width=\"1\"/>\n"
        , container_h, w, h, w
    );
    #if CHANS >= 2
    fprintf(file,
        "        <rect x=\"0\" y=\"256\" width=\"%u\" height=\"256\" stroke=\"grey\" fill=\"transparent\" stroke-width=\"1\"/>\n"
        , w
    );
    #endif
    /*
    for (uint t = t0; t < t1; t += 256) fprintf(file,
        "        <text x=\"%u\" y=\"256\" class=\"t-marker\">t=%u</text>\n"
        , t - t0, t
    );
    */
    fprintf(file,
        "        <g>\n"
        "            <polyline\n"
        "                stroke=\"black\" fill=\"transparent\" stroke-width=\".75\"\n"
        "                points=\"\n"
    );
    prog(file, t0, t1, 's');
    fprintf(file,
        "                \"\n"
        "            />\n"
        "        </g>\n"
    );
    #if CHANS >= 2
    fprintf(file,
        "        <g>\n"
        "            <polyline\n"
        "                stroke=\"black\" fill=\"transparent\" stroke-width=\".75\"\n"
        "                points=\"\n"
    );
    prog(file, t0, t1, 't');
    fprintf(file,
        "                \"\n"
        "            />\n"
        "        </g>\n"
    );
    #endif
    fprintf(file,
        "    </svg>\n"
        "</div>\n"
    );
    if (fullpage) fprintf(file,
        "</body>\n"
        "</html>\n"
    );
}


bool startswith(const char *s1, const char *s2) {
    return !strncmp(s1, s2, strlen(s2));
}


int main(int n_args, char **args){
    int chans = 2; /* channels */
    uint t0 = 0, t1 = 0;
    char mode = 'b'; /* 'b': output raw bytes, 's'/'S': render SVG */

    for (int i = 1; i < n_args; i++) {
        char *arg = args[i];
        if (startswith(arg, "mode=")) {
            mode = arg[5];
            if (!strchr(MODES, mode)) {
                fprintf(stderr, "Unrecognized mode: [%c] (Expected one of: [%s])\n", mode, MODES);
                exit(1);
            }
        } else if (startswith(arg, "chans=")) {
            chans = atoi(arg + 6);
        } else if (startswith(arg, "t0=")) {
            t0 = atoi(arg + 3);
        } else if (startswith(arg, "t1=")) {
            t1 = atoi(arg + 3);
        } else {
            fprintf(stderr, "Unrecognized option: %s\n", arg);
            exit(1);
        }
    }

    if (mode == 's' || mode == 'S') {
        if (!t1) {
            fprintf(stderr, "Require an end time (t1) for SVG rendering\n");
            exit(1);
        }
        print_svg(stdout, t0, t1, mode == 'S');
    } else {
        prog(stdout, t0, t1, mode);
    }
    return 0;
}
