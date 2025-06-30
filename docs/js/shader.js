const canvas = document.getElementById('glCanvas');
const gl = canvas.getContext('webgl2');
if (!gl) {
  alert('WebGL2 not supported');
  throw new Error('WebGL2 not supported');
}

canvas.width = canvas.clientWidth;
canvas.height = canvas.clientHeight;

function resize() {
  const displayWidth = canvas.clientWidth;
  const displayHeight = canvas.clientHeight;
  if (canvas.width !== displayWidth || canvas.height !== displayHeight) {
    canvas.width = displayWidth;
    canvas.height = displayHeight;
  }
  gl.viewport(0, 0, canvas.width, canvas.height);
}
window.addEventListener('resize', resize);

async function loadShaderSource(url) {
  try {
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`Failed to fetch shader: ${res.status} ${res.statusText}`);
    }
    return await res.text();
  } catch (error) {
    console.error('Error loading shader from:', url, error);
    throw error;
  }
}

function createShader(gl, type, source) {
  const shader = gl.createShader(type);
  gl.shaderSource(shader, source);
  gl.compileShader(shader);
  if (!gl.getShaderParameter(shader, gl.COMPILE_STATUS)) {
    console.error(gl.getShaderInfoLog(shader));
    gl.deleteShader(shader);
    throw new Error('Shader compile failed');
  }
  return shader;
}

function createProgram(gl, vsSource, fsSource) {
  const vs = createShader(gl, gl.VERTEX_SHADER, vsSource);
  const fs = createShader(gl, gl.FRAGMENT_SHADER, fsSource);
  const prog = gl.createProgram();
  gl.attachShader(prog, vs);
  gl.attachShader(prog, fs);
  gl.linkProgram(prog);
  if (!gl.getProgramParameter(prog, gl.LINK_STATUS)) {
    console.error(gl.getProgramInfoLog(prog));
    gl.deleteProgram(prog);
    throw new Error('Program link failed');
  }
  return prog;
}

(async () => {
  try {
    // Load the shader relative to the HTML file rather than this module's path
    // so it works correctly when served from GitHub Pages.
    let fs = await loadShaderSource('./shaders/raymarchingChair.glsl');
    const header = `#version 300 es\nprecision highp float;\nuniform vec3 iResolution;\nuniform float iTime;\nout vec4 outColor;\n`;
    const footer = `\nvoid main(){\n    mainImage(outColor, gl_FragCoord.xy);\n}`;
    const fsSource = header + fs + footer;

  const vsSource = `#version 300 es\nprecision highp float;\nin vec4 aPosition;\nvoid main() {\n  gl_Position = aPosition;\n}`;
  const program = createProgram(gl, vsSource, fsSource);
  const positionBuffer = gl.createBuffer();
  gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
  gl.bufferData(gl.ARRAY_BUFFER, new Float32Array([
    -1, -1,
     1, -1,
    -1,  1,
    -1,  1,
     1, -1,
     1,  1,
  ]), gl.STATIC_DRAW);

  const vao = gl.createVertexArray();
  gl.bindVertexArray(vao);
  const posLoc = gl.getAttribLocation(program, 'aPosition');
  gl.enableVertexAttribArray(posLoc);
  gl.vertexAttribPointer(posLoc, 2, gl.FLOAT, false, 0, 0);

  const iResolutionLoc = gl.getUniformLocation(program, 'iResolution');
  const iTimeLoc = gl.getUniformLocation(program, 'iTime');

  function render(time) {
    resize();
    gl.useProgram(program);
    gl.bindVertexArray(vao);
    gl.uniform3f(iResolutionLoc, canvas.width, canvas.height, 1.0);
    gl.uniform1f(iTimeLoc, time * 0.001);
    gl.drawArrays(gl.TRIANGLES, 0, 6);
    requestAnimationFrame(render);
  }
  requestAnimationFrame(render);
  } catch (error) {
    console.error('Failed to initialize shader:', error);
    document.body.innerHTML = '<div style="color: red; padding: 20px;">Failed to load shader: ' + error.message + '</div>';
  }
})();
