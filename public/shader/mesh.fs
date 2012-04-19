#ifdef GL_ES                 
precision mediump float;     
#endif                       
                          
varying vec4 frontColor;   
varying vec3 lightWeighting;
void main(void){                
	gl_FragColor = vec4(frontColor.rgb * lightWeighting, frontColor.a);    
}
