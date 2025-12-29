/**
 * @license
 * Copyright 2019 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const j=globalThis,J=j.ShadowRoot&&(j.ShadyCSS===void 0||j.ShadyCSS.nativeShadow)&&"adoptedStyleSheets"in Document.prototype&&"replace"in CSSStyleSheet.prototype,K=Symbol(),G=new WeakMap;let ct=class{constructor(t,e,s){if(this._$cssResult$=!0,s!==K)throw Error("CSSResult is not constructable. Use `unsafeCSS` or `css` instead.");this.cssText=t,this.t=e}get styleSheet(){let t=this.o;const e=this.t;if(J&&t===void 0){const s=e!==void 0&&e.length===1;s&&(t=G.get(e)),t===void 0&&((this.o=t=new CSSStyleSheet).replaceSync(this.cssText),s&&G.set(e,t))}return t}toString(){return this.cssText}};const mt=r=>new ct(typeof r=="string"?r:r+"",void 0,K),lt=(r,...t)=>{const e=r.length===1?r[0]:t.reduce((s,i,n)=>s+(o=>{if(o._$cssResult$===!0)return o.cssText;if(typeof o=="number")return o;throw Error("Value passed to 'css' function must be a 'css' function result: "+o+". Use 'unsafeCSS' to pass non-literal values, but take care to ensure page security.")})(i)+r[n+1],r[0]);return new ct(e,r,K)},_t=(r,t)=>{if(J)r.adoptedStyleSheets=t.map(e=>e instanceof CSSStyleSheet?e:e.styleSheet);else for(const e of t){const s=document.createElement("style"),i=j.litNonce;i!==void 0&&s.setAttribute("nonce",i),s.textContent=e.cssText,r.appendChild(s)}},Q=J?r=>r:r=>r instanceof CSSStyleSheet?(t=>{let e="";for(const s of t.cssRules)e+=s.cssText;return mt(e)})(r):r;/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const{is:gt,defineProperty:bt,getOwnPropertyDescriptor:yt,getOwnPropertyNames:vt,getOwnPropertySymbols:At,getPrototypeOf:Et}=Object,m=globalThis,X=m.trustedTypes,St=X?X.emptyScript:"",B=m.reactiveElementPolyfillSupport,N=(r,t)=>r,L={toAttribute(r,t){switch(t){case Boolean:r=r?St:null;break;case Object:case Array:r=r==null?r:JSON.stringify(r)}return r},fromAttribute(r,t){let e=r;switch(t){case Boolean:e=r!==null;break;case Number:e=r===null?null:Number(r);break;case Object:case Array:try{e=JSON.parse(r)}catch{e=null}}return e}},F=(r,t)=>!gt(r,t),tt={attribute:!0,type:String,converter:L,reflect:!1,useDefault:!1,hasChanged:F};Symbol.metadata??(Symbol.metadata=Symbol("metadata")),m.litPropertyMetadata??(m.litPropertyMetadata=new WeakMap);let E=class extends HTMLElement{static addInitializer(t){this._$Ei(),(this.l??(this.l=[])).push(t)}static get observedAttributes(){return this.finalize(),this._$Eh&&[...this._$Eh.keys()]}static createProperty(t,e=tt){if(e.state&&(e.attribute=!1),this._$Ei(),this.prototype.hasOwnProperty(t)&&((e=Object.create(e)).wrapped=!0),this.elementProperties.set(t,e),!e.noAccessor){const s=Symbol(),i=this.getPropertyDescriptor(t,s,e);i!==void 0&&bt(this.prototype,t,i)}}static getPropertyDescriptor(t,e,s){const{get:i,set:n}=yt(this.prototype,t)??{get(){return this[e]},set(o){this[e]=o}};return{get:i,set(o){const h=i==null?void 0:i.call(this);n==null||n.call(this,o),this.requestUpdate(t,h,s)},configurable:!0,enumerable:!0}}static getPropertyOptions(t){return this.elementProperties.get(t)??tt}static _$Ei(){if(this.hasOwnProperty(N("elementProperties")))return;const t=Et(this);t.finalize(),t.l!==void 0&&(this.l=[...t.l]),this.elementProperties=new Map(t.elementProperties)}static finalize(){if(this.hasOwnProperty(N("finalized")))return;if(this.finalized=!0,this._$Ei(),this.hasOwnProperty(N("properties"))){const e=this.properties,s=[...vt(e),...At(e)];for(const i of s)this.createProperty(i,e[i])}const t=this[Symbol.metadata];if(t!==null){const e=litPropertyMetadata.get(t);if(e!==void 0)for(const[s,i]of e)this.elementProperties.set(s,i)}this._$Eh=new Map;for(const[e,s]of this.elementProperties){const i=this._$Eu(e,s);i!==void 0&&this._$Eh.set(i,e)}this.elementStyles=this.finalizeStyles(this.styles)}static finalizeStyles(t){const e=[];if(Array.isArray(t)){const s=new Set(t.flat(1/0).reverse());for(const i of s)e.unshift(Q(i))}else t!==void 0&&e.push(Q(t));return e}static _$Eu(t,e){const s=e.attribute;return s===!1?void 0:typeof s=="string"?s:typeof t=="string"?t.toLowerCase():void 0}constructor(){super(),this._$Ep=void 0,this.isUpdatePending=!1,this.hasUpdated=!1,this._$Em=null,this._$Ev()}_$Ev(){var t;this._$ES=new Promise(e=>this.enableUpdating=e),this._$AL=new Map,this._$E_(),this.requestUpdate(),(t=this.constructor.l)==null||t.forEach(e=>e(this))}addController(t){var e;(this._$EO??(this._$EO=new Set)).add(t),this.renderRoot!==void 0&&this.isConnected&&((e=t.hostConnected)==null||e.call(t))}removeController(t){var e;(e=this._$EO)==null||e.delete(t)}_$E_(){const t=new Map,e=this.constructor.elementProperties;for(const s of e.keys())this.hasOwnProperty(s)&&(t.set(s,this[s]),delete this[s]);t.size>0&&(this._$Ep=t)}createRenderRoot(){const t=this.shadowRoot??this.attachShadow(this.constructor.shadowRootOptions);return _t(t,this.constructor.elementStyles),t}connectedCallback(){var t;this.renderRoot??(this.renderRoot=this.createRenderRoot()),this.enableUpdating(!0),(t=this._$EO)==null||t.forEach(e=>{var s;return(s=e.hostConnected)==null?void 0:s.call(e)})}enableUpdating(t){}disconnectedCallback(){var t;(t=this._$EO)==null||t.forEach(e=>{var s;return(s=e.hostDisconnected)==null?void 0:s.call(e)})}attributeChangedCallback(t,e,s){this._$AK(t,s)}_$ET(t,e){var n;const s=this.constructor.elementProperties.get(t),i=this.constructor._$Eu(t,s);if(i!==void 0&&s.reflect===!0){const o=(((n=s.converter)==null?void 0:n.toAttribute)!==void 0?s.converter:L).toAttribute(e,s.type);this._$Em=t,o==null?this.removeAttribute(i):this.setAttribute(i,o),this._$Em=null}}_$AK(t,e){var n,o;const s=this.constructor,i=s._$Eh.get(t);if(i!==void 0&&this._$Em!==i){const h=s.getPropertyOptions(i),a=typeof h.converter=="function"?{fromAttribute:h.converter}:((n=h.converter)==null?void 0:n.fromAttribute)!==void 0?h.converter:L;this._$Em=i;const l=a.fromAttribute(e,h.type);this[i]=l??((o=this._$Ej)==null?void 0:o.get(i))??l,this._$Em=null}}requestUpdate(t,e,s,i=!1,n){var o;if(t!==void 0){const h=this.constructor;if(i===!1&&(n=this[t]),s??(s=h.getPropertyOptions(t)),!((s.hasChanged??F)(n,e)||s.useDefault&&s.reflect&&n===((o=this._$Ej)==null?void 0:o.get(t))&&!this.hasAttribute(h._$Eu(t,s))))return;this.C(t,e,s)}this.isUpdatePending===!1&&(this._$ES=this._$EP())}C(t,e,{useDefault:s,reflect:i,wrapped:n},o){s&&!(this._$Ej??(this._$Ej=new Map)).has(t)&&(this._$Ej.set(t,o??e??this[t]),n!==!0||o!==void 0)||(this._$AL.has(t)||(this.hasUpdated||s||(e=void 0),this._$AL.set(t,e)),i===!0&&this._$Em!==t&&(this._$Eq??(this._$Eq=new Set)).add(t))}async _$EP(){this.isUpdatePending=!0;try{await this._$ES}catch(e){Promise.reject(e)}const t=this.scheduleUpdate();return t!=null&&await t,!this.isUpdatePending}scheduleUpdate(){return this.performUpdate()}performUpdate(){var s;if(!this.isUpdatePending)return;if(!this.hasUpdated){if(this.renderRoot??(this.renderRoot=this.createRenderRoot()),this._$Ep){for(const[n,o]of this._$Ep)this[n]=o;this._$Ep=void 0}const i=this.constructor.elementProperties;if(i.size>0)for(const[n,o]of i){const{wrapped:h}=o,a=this[n];h!==!0||this._$AL.has(n)||a===void 0||this.C(n,void 0,o,a)}}let t=!1;const e=this._$AL;try{t=this.shouldUpdate(e),t?(this.willUpdate(e),(s=this._$EO)==null||s.forEach(i=>{var n;return(n=i.hostUpdate)==null?void 0:n.call(i)}),this.update(e)):this._$EM()}catch(i){throw t=!1,this._$EM(),i}t&&this._$AE(e)}willUpdate(t){}_$AE(t){var e;(e=this._$EO)==null||e.forEach(s=>{var i;return(i=s.hostUpdated)==null?void 0:i.call(s)}),this.hasUpdated||(this.hasUpdated=!0,this.firstUpdated(t)),this.updated(t)}_$EM(){this._$AL=new Map,this.isUpdatePending=!1}get updateComplete(){return this.getUpdateComplete()}getUpdateComplete(){return this._$ES}shouldUpdate(t){return!0}update(t){this._$Eq&&(this._$Eq=this._$Eq.forEach(e=>this._$ET(e,this[e]))),this._$EM()}updated(t){}firstUpdated(t){}};E.elementStyles=[],E.shadowRootOptions={mode:"open"},E[N("elementProperties")]=new Map,E[N("finalized")]=new Map,B==null||B({ReactiveElement:E}),(m.reactiveElementVersions??(m.reactiveElementVersions=[])).push("2.1.2");/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const M=globalThis,et=r=>r,z=M.trustedTypes,st=z?z.createPolicy("lit-html",{createHTML:r=>r}):void 0,dt="$lit$",f=`lit$${Math.random().toFixed(9).slice(2)}$`,ut="?"+f,wt=`<${ut}>`,A=document,T=()=>A.createComment(""),H=r=>r===null||typeof r!="object"&&typeof r!="function",Y=Array.isArray,xt=r=>Y(r)||typeof(r==null?void 0:r[Symbol.iterator])=="function",q=`[ 	
\f\r]`,O=/<(?:(!--|\/[^a-zA-Z])|(\/?[a-zA-Z][^>\s]*)|(\/?$))/g,it=/-->/g,rt=/>/g,b=RegExp(`>|${q}(?:([^\\s"'>=/]+)(${q}*=${q}*(?:[^ 	
\f\r"'\`<>=]|("|')|))|$)`,"g"),ot=/'/g,nt=/"/g,pt=/^(?:script|style|textarea|title)$/i,Ct=r=>(t,...e)=>({_$litType$:r,strings:t,values:e}),U=Ct(1),w=Symbol.for("lit-noChange"),d=Symbol.for("lit-nothing"),at=new WeakMap,y=A.createTreeWalker(A,129);function $t(r,t){if(!Y(r)||!r.hasOwnProperty("raw"))throw Error("invalid template strings array");return st!==void 0?st.createHTML(t):t}const Pt=(r,t)=>{const e=r.length-1,s=[];let i,n=t===2?"<svg>":t===3?"<math>":"",o=O;for(let h=0;h<e;h++){const a=r[h];let l,u,c=-1,p=0;for(;p<a.length&&(o.lastIndex=p,u=o.exec(a),u!==null);)p=o.lastIndex,o===O?u[1]==="!--"?o=it:u[1]!==void 0?o=rt:u[2]!==void 0?(pt.test(u[2])&&(i=RegExp("</"+u[2],"g")),o=b):u[3]!==void 0&&(o=b):o===b?u[0]===">"?(o=i??O,c=-1):u[1]===void 0?c=-2:(c=o.lastIndex-u[2].length,l=u[1],o=u[3]===void 0?b:u[3]==='"'?nt:ot):o===nt||o===ot?o=b:o===it||o===rt?o=O:(o=b,i=void 0);const $=o===b&&r[h+1].startsWith("/>")?" ":"";n+=o===O?a+wt:c>=0?(s.push(l),a.slice(0,c)+dt+a.slice(c)+f+$):a+f+(c===-2?h:$)}return[$t(r,n+(r[e]||"<?>")+(t===2?"</svg>":t===3?"</math>":"")),s]};class R{constructor({strings:t,_$litType$:e},s){let i;this.parts=[];let n=0,o=0;const h=t.length-1,a=this.parts,[l,u]=Pt(t,e);if(this.el=R.createElement(l,s),y.currentNode=this.el.content,e===2||e===3){const c=this.el.content.firstChild;c.replaceWith(...c.childNodes)}for(;(i=y.nextNode())!==null&&a.length<h;){if(i.nodeType===1){if(i.hasAttributes())for(const c of i.getAttributeNames())if(c.endsWith(dt)){const p=u[o++],$=i.getAttribute(c).split(f),D=/([.?@])?(.*)/.exec(p);a.push({type:1,index:n,name:D[2],strings:$,ctor:D[1]==="."?Ut:D[1]==="?"?Nt:D[1]==="@"?Mt:I}),i.removeAttribute(c)}else c.startsWith(f)&&(a.push({type:6,index:n}),i.removeAttribute(c));if(pt.test(i.tagName)){const c=i.textContent.split(f),p=c.length-1;if(p>0){i.textContent=z?z.emptyScript:"";for(let $=0;$<p;$++)i.append(c[$],T()),y.nextNode(),a.push({type:2,index:++n});i.append(c[p],T())}}}else if(i.nodeType===8)if(i.data===ut)a.push({type:2,index:n});else{let c=-1;for(;(c=i.data.indexOf(f,c+1))!==-1;)a.push({type:7,index:n}),c+=f.length-1}n++}}static createElement(t,e){const s=A.createElement("template");return s.innerHTML=t,s}}function x(r,t,e=r,s){var o,h;if(t===w)return t;let i=s!==void 0?(o=e._$Co)==null?void 0:o[s]:e._$Cl;const n=H(t)?void 0:t._$litDirective$;return(i==null?void 0:i.constructor)!==n&&((h=i==null?void 0:i._$AO)==null||h.call(i,!1),n===void 0?i=void 0:(i=new n(r),i._$AT(r,e,s)),s!==void 0?(e._$Co??(e._$Co=[]))[s]=i:e._$Cl=i),i!==void 0&&(t=x(r,i._$AS(r,t.values),i,s)),t}class Ot{constructor(t,e){this._$AV=[],this._$AN=void 0,this._$AD=t,this._$AM=e}get parentNode(){return this._$AM.parentNode}get _$AU(){return this._$AM._$AU}u(t){const{el:{content:e},parts:s}=this._$AD,i=((t==null?void 0:t.creationScope)??A).importNode(e,!0);y.currentNode=i;let n=y.nextNode(),o=0,h=0,a=s[0];for(;a!==void 0;){if(o===a.index){let l;a.type===2?l=new k(n,n.nextSibling,this,t):a.type===1?l=new a.ctor(n,a.name,a.strings,this,t):a.type===6&&(l=new Tt(n,this,t)),this._$AV.push(l),a=s[++h]}o!==(a==null?void 0:a.index)&&(n=y.nextNode(),o++)}return y.currentNode=A,i}p(t){let e=0;for(const s of this._$AV)s!==void 0&&(s.strings!==void 0?(s._$AI(t,s,e),e+=s.strings.length-2):s._$AI(t[e])),e++}}class k{get _$AU(){var t;return((t=this._$AM)==null?void 0:t._$AU)??this._$Cv}constructor(t,e,s,i){this.type=2,this._$AH=d,this._$AN=void 0,this._$AA=t,this._$AB=e,this._$AM=s,this.options=i,this._$Cv=(i==null?void 0:i.isConnected)??!0}get parentNode(){let t=this._$AA.parentNode;const e=this._$AM;return e!==void 0&&(t==null?void 0:t.nodeType)===11&&(t=e.parentNode),t}get startNode(){return this._$AA}get endNode(){return this._$AB}_$AI(t,e=this){t=x(this,t,e),H(t)?t===d||t==null||t===""?(this._$AH!==d&&this._$AR(),this._$AH=d):t!==this._$AH&&t!==w&&this._(t):t._$litType$!==void 0?this.$(t):t.nodeType!==void 0?this.T(t):xt(t)?this.k(t):this._(t)}O(t){return this._$AA.parentNode.insertBefore(t,this._$AB)}T(t){this._$AH!==t&&(this._$AR(),this._$AH=this.O(t))}_(t){this._$AH!==d&&H(this._$AH)?this._$AA.nextSibling.data=t:this.T(A.createTextNode(t)),this._$AH=t}$(t){var n;const{values:e,_$litType$:s}=t,i=typeof s=="number"?this._$AC(t):(s.el===void 0&&(s.el=R.createElement($t(s.h,s.h[0]),this.options)),s);if(((n=this._$AH)==null?void 0:n._$AD)===i)this._$AH.p(e);else{const o=new Ot(i,this),h=o.u(this.options);o.p(e),this.T(h),this._$AH=o}}_$AC(t){let e=at.get(t.strings);return e===void 0&&at.set(t.strings,e=new R(t)),e}k(t){Y(this._$AH)||(this._$AH=[],this._$AR());const e=this._$AH;let s,i=0;for(const n of t)i===e.length?e.push(s=new k(this.O(T()),this.O(T()),this,this.options)):s=e[i],s._$AI(n),i++;i<e.length&&(this._$AR(s&&s._$AB.nextSibling,i),e.length=i)}_$AR(t=this._$AA.nextSibling,e){var s;for((s=this._$AP)==null?void 0:s.call(this,!1,!0,e);t!==this._$AB;){const i=et(t).nextSibling;et(t).remove(),t=i}}setConnected(t){var e;this._$AM===void 0&&(this._$Cv=t,(e=this._$AP)==null||e.call(this,t))}}class I{get tagName(){return this.element.tagName}get _$AU(){return this._$AM._$AU}constructor(t,e,s,i,n){this.type=1,this._$AH=d,this._$AN=void 0,this.element=t,this.name=e,this._$AM=i,this.options=n,s.length>2||s[0]!==""||s[1]!==""?(this._$AH=Array(s.length-1).fill(new String),this.strings=s):this._$AH=d}_$AI(t,e=this,s,i){const n=this.strings;let o=!1;if(n===void 0)t=x(this,t,e,0),o=!H(t)||t!==this._$AH&&t!==w,o&&(this._$AH=t);else{const h=t;let a,l;for(t=n[0],a=0;a<n.length-1;a++)l=x(this,h[s+a],e,a),l===w&&(l=this._$AH[a]),o||(o=!H(l)||l!==this._$AH[a]),l===d?t=d:t!==d&&(t+=(l??"")+n[a+1]),this._$AH[a]=l}o&&!i&&this.j(t)}j(t){t===d?this.element.removeAttribute(this.name):this.element.setAttribute(this.name,t??"")}}class Ut extends I{constructor(){super(...arguments),this.type=3}j(t){this.element[this.name]=t===d?void 0:t}}class Nt extends I{constructor(){super(...arguments),this.type=4}j(t){this.element.toggleAttribute(this.name,!!t&&t!==d)}}class Mt extends I{constructor(t,e,s,i,n){super(t,e,s,i,n),this.type=5}_$AI(t,e=this){if((t=x(this,t,e,0)??d)===w)return;const s=this._$AH,i=t===d&&s!==d||t.capture!==s.capture||t.once!==s.once||t.passive!==s.passive,n=t!==d&&(s===d||i);i&&this.element.removeEventListener(this.name,this,s),n&&this.element.addEventListener(this.name,this,t),this._$AH=t}handleEvent(t){var e;typeof this._$AH=="function"?this._$AH.call(((e=this.options)==null?void 0:e.host)??this.element,t):this._$AH.handleEvent(t)}}class Tt{constructor(t,e,s){this.element=t,this.type=6,this._$AN=void 0,this._$AM=e,this.options=s}get _$AU(){return this._$AM._$AU}_$AI(t){x(this,t)}}const W=M.litHtmlPolyfillSupport;W==null||W(R,k),(M.litHtmlVersions??(M.litHtmlVersions=[])).push("3.3.2");const Ht=(r,t,e)=>{const s=(e==null?void 0:e.renderBefore)??t;let i=s._$litPart$;if(i===void 0){const n=(e==null?void 0:e.renderBefore)??null;s._$litPart$=i=new k(t.insertBefore(T(),n),n,void 0,e??{})}return i._$AI(r),i};/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const v=globalThis;class S extends E{constructor(){super(...arguments),this.renderOptions={host:this},this._$Do=void 0}createRenderRoot(){var e;const t=super.createRenderRoot();return(e=this.renderOptions).renderBefore??(e.renderBefore=t.firstChild),t}update(t){const e=this.render();this.hasUpdated||(this.renderOptions.isConnected=this.isConnected),super.update(t),this._$Do=Ht(e,this.renderRoot,this.renderOptions)}connectedCallback(){var t;super.connectedCallback(),(t=this._$Do)==null||t.setConnected(!0)}disconnectedCallback(){var t;super.disconnectedCallback(),(t=this._$Do)==null||t.setConnected(!1)}render(){return w}}var ht;S._$litElement$=!0,S.finalized=!0,(ht=v.litElementHydrateSupport)==null||ht.call(v,{LitElement:S});const Z=v.litElementPolyfillSupport;Z==null||Z({LitElement:S});(v.litElementVersions??(v.litElementVersions=[])).push("4.2.2");/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const ft=r=>(t,e)=>{e!==void 0?e.addInitializer(()=>{customElements.define(r,t)}):customElements.define(r,t)};/**
 * @license
 * Copyright 2017 Google LLC
 * SPDX-License-Identifier: BSD-3-Clause
 */const Rt={attribute:!0,type:String,converter:L,reflect:!1,hasChanged:F},kt=(r=Rt,t,e)=>{const{kind:s,metadata:i}=e;let n=globalThis.litPropertyMetadata.get(i);if(n===void 0&&globalThis.litPropertyMetadata.set(i,n=new Map),s==="setter"&&((r=Object.create(r)).wrapped=!0),n.set(e.name,r),s==="accessor"){const{name:o}=e;return{set(h){const a=t.get.call(this);t.set.call(this,h),this.requestUpdate(o,a,r,!0,h)},init(h){return h!==void 0&&this.C(o,void 0,r,h),h}}}if(s==="setter"){const{name:o}=e;return function(h){const a=this[o];t.call(this,h),this.requestUpdate(o,a,r,!0,h)}}throw Error("Unsupported decorator location: "+s)};function g(r){return(t,e)=>typeof e=="object"?kt(r,t,e):((s,i,n)=>{const o=i.hasOwnProperty(n);return i.constructor.createProperty(n,s),o?Object.getOwnPropertyDescriptor(i,n):void 0})(r,t,e)}var Dt=Object.defineProperty,jt=Object.getOwnPropertyDescriptor,P=(r,t,e,s)=>{for(var i=s>1?void 0:s?jt(t,e):t,n=r.length-1,o;n>=0;n--)(o=r[n])&&(i=(s?o(t,e,i):o(i))||i);return s&&i&&Dt(t,e,i),i};let _=class extends S{constructor(){super(...arguments),this.count=0,this.initialValue=0,this.step=1}connectedCallback(){super.connectedCallback(),this.count=this.initialValue}increment(){const r=this.count+this.step;(this.max===void 0||r<=this.max)&&(this.count=r,this.dispatchEvent(new CustomEvent("count-changed",{detail:{count:this.count},bubbles:!0,composed:!0})))}decrement(){const r=this.count-this.step;(this.min===void 0||r>=this.min)&&(this.count=r,this.dispatchEvent(new CustomEvent("count-changed",{detail:{count:this.count},bubbles:!0,composed:!0})))}reset(){this.count=this.initialValue,this.dispatchEvent(new CustomEvent("count-changed",{detail:{count:this.count},bubbles:!0,composed:!0}))}render(){const r=this.min===void 0||this.count>this.min,t=this.max===void 0||this.count<this.max,e=this.count===this.initialValue;return U`
      <div class="counter-container">
        <button
          @click=${this.decrement}
          ?disabled=${!r}
          aria-label="Decrement"
        >
          −
        </button>
        <span class="counter-value">${this.count}</span>
        <button
          @click=${this.increment}
          ?disabled=${!t}
          aria-label="Increment"
        >
          +
        </button>
        <button
          class="reset-button"
          @click=${this.reset}
          ?disabled=${e}
          aria-label="Reset"
        >
          Reset
        </button>
      </div>
    `}};_.styles=lt`
    :host {
      display: block;
      padding: 1rem;
      border: 2px solid #e5e7eb;
      border-radius: 0.5rem;
      background-color: #ffffff;
    }

    .counter-container {
      display: flex;
      align-items: center;
      gap: 1rem;
    }

    .counter-value {
      font-size: 1.5rem;
      font-weight: bold;
      color: #1f2937;
      min-width: 3rem;
      text-align: center;
    }

    button {
      padding: 0.5rem 1rem;
      font-size: 1rem;
      font-weight: 600;
      color: #ffffff;
      background-color: #3b82f6;
      border: none;
      border-radius: 0.375rem;
      cursor: pointer;
      transition: background-color 0.2s;
    }

    button:hover {
      background-color: #2563eb;
    }

    button:active {
      background-color: #1d4ed8;
    }

    button:disabled {
      background-color: #9ca3af;
      cursor: not-allowed;
    }

    .reset-button {
      background-color: #6b7280;
      margin-left: auto;
    }

    .reset-button:hover {
      background-color: #4b5563;
    }
  `;P([g({type:Number})],_.prototype,"count",2);P([g({type:Number,attribute:"initial-value"})],_.prototype,"initialValue",2);P([g({type:Number,attribute:"step"})],_.prototype,"step",2);P([g({type:Number,attribute:"min"})],_.prototype,"min",2);P([g({type:Number,attribute:"max"})],_.prototype,"max",2);_=P([ft("ny-counter")],_);var Lt=Object.defineProperty,zt=Object.getOwnPropertyDescriptor,V=(r,t,e,s)=>{for(var i=s>1?void 0:s?zt(t,e):t,n=r.length-1,o;n>=0;n--)(o=r[n])&&(i=(s?o(t,e,i):o(i))||i);return s&&i&&Lt(t,e,i),i};let C=class extends S{constructor(){super(...arguments),this.title="",this.image="",this.description=""}render(){return U`
      <div class="card">
        ${this.image?U`
          <img
            src=${this.image}
            alt=${this.title||"Card image"}
            class="card-image"
            loading="lazy"
          />
        `:""}
        <div class="card-content">
          ${this.title?U`
            <h3 class="card-title">${this.title}</h3>
          `:""}
          ${this.description?U`
            <p class="card-description">${this.description}</p>
          `:""}
          <slot name="actions"></slot>
        </div>
        <div class="card-footer">
          <slot name="footer"></slot>
        </div>
      </div>
    `}};C.styles=lt`
    :host {
      display: block;
    }

    .card {
      background-color: #ffffff;
      border-radius: 0.5rem;
      box-shadow: 0 1px 3px 0 rgba(0, 0, 0, 0.1), 0 1px 2px 0 rgba(0, 0, 0, 0.06);
      overflow: hidden;
      transition: box-shadow 0.2s, transform 0.2s;
    }

    .card:hover {
      box-shadow: 0 10px 15px -3px rgba(0, 0, 0, 0.1), 0 4px 6px -2px rgba(0, 0, 0, 0.05);
      transform: translateY(-2px);
    }

    .card-image {
      width: 100%;
      height: 200px;
      object-fit: cover;
      display: block;
    }

    .card-content {
      padding: 1.5rem;
    }

    .card-title {
      font-size: 1.25rem;
      font-weight: 600;
      color: #1f2937;
      margin: 0 0 0.75rem 0;
    }

    .card-description {
      color: #6b7280;
      line-height: 1.6;
      margin: 0 0 1rem 0;
    }

    .card-footer {
      padding: 1rem 1.5rem;
      background-color: #f9fafb;
      border-top: 1px solid #e5e7eb;
    }

    ::slotted([slot="footer"]) {
      margin: 0;
    }

    ::slotted([slot="actions"]) {
      display: flex;
      gap: 0.5rem;
      margin-top: 1rem;
    }
  `;V([g({type:String})],C.prototype,"title",2);V([g({type:String})],C.prototype,"image",2);V([g({type:String})],C.prototype,"description",2);C=V([ft("ny-card")],C);document.addEventListener("DOMContentLoaded",()=>{console.log("Nyardpress theme loaded"),It()});function It(){const r=document.querySelector(".mobile-menu-toggle"),t=document.querySelector(".mobile-menu");r&&t&&r.addEventListener("click",()=>{t.classList.toggle("hidden")}),document.addEventListener("count-changed",e=>{console.log("Counter changed:",e.detail.count)})}
