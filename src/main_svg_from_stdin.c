#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>

#include "parser.h"
#include "renderer.h"

#define BUF_SIZE 1048576 // 1 MB hardcoded, not great, not terrible

int main(int argc, char* argv[])
{   
    char fcontent[BUF_SIZE]; 
    
    fread(fcontent, 1, BUF_SIZE, stdin);
    
    chart * c = parse_chart(fcontent);
    char * svg = chart_to_svg(c);
    
    printf("%s\n", svg);

    chart_free(c);
    free(svg);

    return 0;
}