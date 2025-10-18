declare module 'bs58' {
  export function encode(input: Uint8Array | Buffer): string;
  export function decode(input: string): Uint8Array;
  const bs58: {
    encode: (input: Uint8Array | Buffer) => string;
    decode: (input: string) => Uint8Array;
  };
  export default bs58;
}
