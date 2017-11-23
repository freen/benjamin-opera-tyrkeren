// Q: which octave does Andrew mean?
// http://www.electronics.dit.ie/staff/tscarff/Music_technology/midi/midi_note_numbers_for_octaves.htm
// https://docs.google.com/document/d/1AdY8mYTAHoDBee3Zoc3bZJsfBM3h2q00d9FHBes0HoY/edit

48.midicps;

(
s.waitForBoot{

    SynthDef(\risset, {|out= 0, pan= 0, freq= 400, amp= 0.1, dur= 2, t_trig= 1|
        var amps= #[1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33];
        var durs= #[1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075];
        var frqs= #[0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07];
        var dets= #[0, 1, 0, 1.7, 0, 0, 0, 0, 0, 0, 0];
        var src= Mix.fill(11, {|i|
            var env= EnvGen.ar(Env.perc(0.005, dur*durs[i], amps[i], -4.5), t_trig);
            SinOsc.ar(freq*frqs[i]+dets[i], 0, amp*env);
        });
        Out.ar(out, Pan2.ar(src, pan));
    }).add;

    /*********
     * BELLS *
     *********/

    // A. Chess players begin
    //    a. Bells
    //       i. For until Andrew’s signal
    //       ii. Pitches (Set 1)
    //          1. C (131.41 Hz)
    //          2. D (156.27 Hz)
    //          3. E (662.25)
    //          4. A (884)
    //          5. B (992.3)
    //          6. E (1314.1)
    //          7. F# (1445.5)

    var bells_notes_set = [
        131.41, // C
        156.27, // D
        662.25, // E
        884,    // A
        992.3,  // B
        1314.1, // E
        1445.5  // F#
    ];

    var player;

    ~w = Window("threshold setting", Rect(15, 100, 300, 100))
        .onClose_({
            ~ampSynth.free;
            ~ampUpdater.free;
            ~oscTrigResp.free;
            player.stop;
        });
    ~w.view.decorator = FlowLayout(~w.view.bounds, 2@2, 2@2);
    ~ampView = EZSlider(~w, 295@20, "amplitude", \amp, labelWidth: 80, numberWidth: 60);
    ~ampView.sliderView.canFocus_(false).enabled_(false);
    ~ampView.numberView.canFocus_(false).enabled_(false);
    StaticText(~w, 295@5).background_(Color.gray);
    ~threshView = EZSlider(~w, 295@30, "threshold", \amp, action: { |ez|
        ~ampSynth.set(\thresh, ez.value);
    }, initVal: 0.4, labelWidth: 80, numberWidth: 60);
    ~decayView = EZSlider(~w, 295@30, "decay", #[0.1, 100, \exp], action: { |ez|
        ~ampSynth.set(\decay, ez.value);
    }, initVal: 80.0, labelWidth: 80, numberWidth: 60);

    ~w.front;

    ~ampSynth = SynthDef(\ampSynth, { |inbus, thresh = 0.8, decay = 1|
        var amp = Amplitude.kr(In.ar(inbus, 1), attackTime: 0.01, releaseTime: decay);
        // this trigger (id==0) is to update the gui only
        SendReply.kr(Impulse.kr(10), '/amp', amp);
        // this trigger gets sent only when amplitude crosses threshold
        SendReply.kr(amp >= thresh, '/amptrig');
    }).play(args: [inbus: s.options.numOutputBusChannels, thresh: ~threshView.value, decay: ~decayView.value]);

    ~ampUpdater = OSCFunc({ |msg|
        defer { ~ampView.value = msg[3] }
    }, '/amp', s.addr);

    ~oscTrigResp = OSCFunc({ |msg|
        if(player.isNil or: { player.isPlaying.not }) {
            /* player = {
                var note_1 = OteyPianoStrings.ar(bells_notes_set.choose),
                   note_2 = OteyPianoStrings.ar(bells_notes_set.choose);
                note_1 = RLPF.ar(note_1) * 0.5;
                note_2 = RLPF.ar(note_2) * 0.5;
                note_1 + note_2;
            }.play;*/

			player = Routine({
				var a= Synth(\risset);
				20.do{
					var dur= 0.2.exprand(3.0);
					var fre= 60.0.exprand(5000.0);
					("dur:"+dur+"fre:"+fre).postln;
					a.set(\t_trig, 1, \freq, fre, \dur, dur);
					dur.wait;
				};
				a.free;
				"done".postln;
			}).play;

        } {
            player.stop;
        };
    }, '/amptrig', s.addr);

}
);
