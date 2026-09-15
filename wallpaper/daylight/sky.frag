#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 stop0; vec4 stop1; vec4 stop2; vec4 stop3; vec4 stop4; vec4 stop5;
    vec4 settings;
    vec2 resolution;
} ubuf;

// Each stop contains an Oklab color and its normalized vertical position.
float slope(float d0,float d1,float h0,float h1) {
    if(d0*d1<=0.)return 0.;
    float w1=2.*h1+h0,w2=h1+2.*h0;
    return (w1+w2)/(w1/d0+w2/d1);
}
float cubic(float y0,float y1,float m0,float m1,float h,float u) {
    return (2.*u*u*u-3.*u*u+1.)*y0+(u*u*u-2.*u*u+u)*h*m0+(-2.*u*u*u+3.*u*u)*y1+(u*u*u-u*u)*h*m1;
}
vec3 rgb(vec3 lab) {
    float L=lab.x,a=lab.y,b=lab.z;
    vec3 lms=vec3(L+.3963377774*a+.2158037573*b,L-.1055613458*a-.0638541728*b,L-.0894841775*a-1.291485548*b);
    lms=lms*lms*lms;
    vec3 v=vec3(dot(vec3(4.0767416621,-3.3077115913,.2309699292),lms),dot(vec3(-1.2684380046,2.6097574011,-.3413193965),lms),dot(vec3(-.0041960863,-.7034186147,1.707614701),lms));
    return mix(12.92*v,1.055*pow(max(v,vec3(0.)),vec3(1./2.4))-.055,step(vec3(.0031308),v));
}
void main() {
    vec4 stops[6];
    stops[0]=ubuf.stop0;stops[1]=ubuf.stop1;stops[2]=ubuf.stop2;
    stops[3]=ubuf.stop3;stops[4]=ubuf.stop4;stops[5]=ubuf.stop5;
    float y=clamp(qt_TexCoord0.y,0.,1.);
    int i=0;
    for(int j=1;j<5;j++)if(y>=stops[j].w)i=j;
    vec4 a=stops[i>0?i-1:0],b=stops[i],c=stops[i+1],d=stops[i<4?i+2:5];
    float h=c.w-b.w,h0=b.w-a.w,h2=d.w-c.w,u=(y-b.w)/h;
    vec3 lab;
    for(int k=0;k<3;k++) {
        float d1=(c[k]-b[k])/h;
        float m0=h0>0.?slope((b[k]-a[k])/h0,d1,h0,h):d1;
        float m1=h2>0.?slope(d1,(d[k]-c[k])/h2,h,h2):d1;
        lab[k]=cubic(b[k],c[k],m0,m1,h,u);
    }
    lab.x=ubuf.settings.x*tanh(lab.x/.75);
    lab.y*=ubuf.settings.y;
    lab.z=lab.z*ubuf.settings.y+ubuf.settings.z*lab.x;
    float chroma=length(lab.yz);
    if(chroma>.085)lab.yz*=.085/chroma;
    vec3 color=rgb(lab);
    for(int j=0;j<16;j++) {
        if(all(greaterThanEqual(color,vec3(0.)))&&all(lessThanEqual(color,vec3(1.))))break;
        lab.yz*=.85;color=rgb(lab);
    }
    vec2 pixel=floor(qt_TexCoord0*ubuf.resolution)+.5;
    float noise=fract(52.9829189*fract(dot(pixel,vec2(.06711056,.00583715))))-.5;
    fragColor=vec4(clamp(color+noise/255.,0.,1.),1.)*ubuf.qt_Opacity;
}
