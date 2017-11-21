(
SynthDef(\strings, { arg out, freq=440, amp=0.1, gate=1, pan, freqLag=0.2;
                                        var env, in, delay, f1, f2;
                                        f1 = freq.lag(freqLag);
                                        f2 = freq.lag(freqLag * 0.5);
                                        delay = 0.25 / f2;
                                        env = Env.asr(0, 1, 0.3);
                                        in = WhiteNoise.ar(180);
                                        in = CombL.ar(in, delay, delay, 1);
                                        in = Resonz.ar(in, f1, 0.001).abs;
                                        in = in * EnvGen.kr(env, gate, doneAction:2);
                                        Out.ar(out, Pan2.ar(in, pan, amp));
}).add;

a = Synth.new(\strings)

(
Pdef(\vi,
        Pbind(
        \instrument, \strings,
        \degree, Pseq([
        Pn(\rest, 2),
        Pshuf([0, 2, 3, 5], 10),
        Pseq([\rest], { 9.rand })
        ], inf)
        + Prand([0, 0, 0, [0, 3], [0, 1]], inf),
        \dur, Pseq([1, 2, 0.3, 0.5, 0.5], inf) + (Prand([0.3, 0, 0.2], inf) * 0.1),
        \detune, Pseg(Pwhite(-2, 2, inf), 1.3)
       )
).play
);
) 