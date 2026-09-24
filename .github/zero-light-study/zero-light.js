// Isolated experiment for the pinned Godot4.7.2 web renderer. Not installed publicly.
(() => {
 'use strict';
 const P=window.WebGL2RenderingContext?.prototype;
 if(!P)return;
 const shaderSource=P.shaderSource,useProgram=P.useProgram,uniform1i=P.uniform1i,linkProgram=P.linkProgram;
 const records=new WeakMap(),contexts=new Set();
 let enabled=false,epoch=0,patched=0,matched=0,activePrograms=0;
 const samples=[];
 const needle='vec4 light_color = textureLod(atlas_texture, tex_uv_atlas, 0.0);';
 const declaration='uniform bool ed_zero_light_skip;\n';
 const insertion=needle+'\n#if !defined(LIGHT_CODE_USED) && !defined(MODE_LIGHT_ONLY)\nif (ed_zero_light_skip && light_color.a == 0.0) { continue; }\n#endif\n';
 P.shaderSource=function(shader,source){
  if(this.getShaderParameter(shader,this.SHADER_TYPE)===this.FRAGMENT_SHADER && source.includes(needle)){
   matched++;
   // Fail closed when renderer structure changes; never patch a near match.
   if(source.split(needle).length===2 && source.split('void main()').length===2 && source.includes('light_blend_compute') && source.includes('light_shadow_compute') && source.includes('shadow_color.a *= light_color.a')){
    source=source.replace(needle,insertion).replace('void main()',declaration+'void main()');patched++;
    if(samples.length<1)samples.push(source);
   }
  }
  return shaderSource.call(this,shader,source);
 };
 function apply(gl,program){
  if(!program)return;
  let record=records.get(program);
  if(!record){
   const location=gl.getUniformLocation(program,'ed_zero_light_skip');
   record={location,epoch:-1};records.set(program,record);
   if(location!==null)activePrograms++;
  }
  if(record.location!==null && record.epoch!==epoch){uniform1i.call(gl,record.location,enabled?1:0);record.epoch=epoch;}
 }
 P.linkProgram=function(program){records.delete(program);return linkProgram.call(this,program);};
 P.useProgram=function(program){const result=useProgram.call(this,program);contexts.add(this);apply(this,program);return result;};
 window.__edZeroLight={
  setEnabled(value){value=!!value;if(enabled===value)return;enabled=value;epoch++;for(const gl of contexts){if(!gl.isContextLost())apply(gl,gl.getParameter(gl.CURRENT_PROGRAM));}},
  snapshot(){return {enabled,patched,matched,activePrograms,epoch};},
  sources(){return samples.slice();}
 };
})();
