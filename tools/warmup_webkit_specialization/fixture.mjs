import { readFile } from 'node:fs/promises';
import vm from 'node:vm';
import assert from 'node:assert/strict';
import { METHODS } from './resources.mjs';
import { METADATA_METHODS } from './identity.mjs';
export const ALL_METHODS=[...METHODS,...METADATA_METHODS];
const observer=await readFile(new URL('observer.js',import.meta.url),'utf8');
const probe=await readFile(new URL('resources.js',import.meta.url),'utf8');
export function fixture({missing,locked}={}) {
  let clock=100,reads=0,throwName=null,nest=false;
  const calls=[],events={},queued=[],returned={},thrown={native_exception:true};
  const native={},proto={};
  for(const name of ALL_METHODS) {
    if(name===missing)continue;
    native[name]=function() {
      calls.push({name,receiver:this,args:Array.from(arguments)});clock+=2;
      if(nest&&name==='texImage2D')gl.compileShader(arguments[0]);
      if(name===throwName)throw thrown;
      if(name==='shaderSource'&&typeof arguments[1]!=='string')String(arguments[1]);
      return returned;
    };
    proto[name]=native[name];
  }
  const gl=Object.create(proto);
  Object.defineProperty(gl,'texStorage2D',{value:native.texStorage2D,writable:!locked,configurable:false,enumerable:true});
  Object.assign(gl,{drawingBufferWidth:1696,drawingBufferHeight:780,getParameter:()=> 'mock',
    drawArrays(){},drawElements(){},drawArraysInstanced(){},drawElementsInstanced(){}});
  function Canvas(){}
  const nativeGet=function(){return this.otherContext||gl;};
  Canvas.prototype.getContext=nativeGet;Canvas.prototype.addEventListener=()=>{};
  const canvas=new Canvas();canvas.id='canvas';canvas.width=1696;canvas.height=780;canvas.getBoundingClientRect=()=>({width:848,height:390});gl.canvas=canvas;
  const nativeGetDescriptor=Object.getOwnPropertyDescriptor(Canvas.prototype,'getContext');
  const nativeDescriptors=ALL_METHODS.map(name=>Object.getOwnPropertyDescriptor(gl,name));
  const raf=callback=>{queued.push(callback);return queued.length;};
  const sandbox={performance:{now:()=>{reads++;return clock;},timeOrigin:1234000},HTMLCanvasElement:Canvas,
    requestAnimationFrame:raf,devicePixelRatio:2,document:{hidden:false,visibilityState:'visible',addEventListener(){}},
    addEventListener:(name,fn)=>{events[name]=fn;}};
  sandbox.window=sandbox;vm.createContext(sandbox);
  vm.runInContext(observer,sandbox);
  const observerGet=Canvas.prototype.getContext,observerDescriptor=Object.getOwnPropertyDescriptor(Canvas.prototype,'getContext');
  vm.runInContext(probe,sandbox);assert.equal(canvas.getContext('webgl2'),gl);
  const api=sandbox.__webkitResourceProbe;
  function pair(texts=['#define VERTEX\nvoid main(){}','#define FRAGMENT\nvoid main(){}']) {
    const shaders=[{},{}],program={};
    shaders.forEach((shader,i)=>{gl.shaderSource(shader,texts[i]);gl.compileShader(shader);gl.getShaderParameter(shader,0x8b81);gl.attachShader(program,shader);});
    gl.linkProgram(program);gl.getProgramParameter(program,0x8b82);return {shaders,program};
  }
  function warm(){gl.texImage2D({});return pair();}
  return {gl,native,api,sandbox,calls,returned,thrown,canvas,Canvas,events,queued,raf,nativeGet,nativeGetDescriptor,nativeDescriptors,observerGet,observerDescriptor,warm,pair,
    get clock(){return clock;},set clock(v){clock=v;},get reads(){return reads;},set throwName(v){throwName=v;},set nest(v){nest=v;}};
}
