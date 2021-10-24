layout(binding=1) buffer Offset {
  uint offset[];
};

uniform uint width;

void main()
{
  atomicAdd(offset[uint(gl_FragCoord.y)*width+uint(gl_FragCoord.x)+1u],1u);
  discard;
}