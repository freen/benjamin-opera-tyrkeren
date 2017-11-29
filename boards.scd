// Q: Which octave does Andrew mean?
// http://www.electronics.dit.ie/staff/tscarff/Music_technology/midi/midi_note_numbers_for_octaves.htm
// https://docs.google.com/document/d/1AdY8mYTAHoDBee3Zoc3bZJsfBM3h2q00d9FHBes0HoY/edit

// TODO:
// - (Bell) Synth release
// - Instrument sets will support per-mic instruments, e.g. var instrument_sets
// - (Piano) Examples include synth release strategy
// - (Piano) Research FreeSelfWhenDone, UGen done-actions
// - Instruments which should play continuous notes, e.g. clarinet?

(
s.waitForBoot{

    // Order of sets must match order of position in pitch set menu.

    var pitch_sets = [
        // Bells Set 1
        [
            131.41, // C
            156.27, // D
            662.25, // E
            884,    // A
            992.3,  // B
            1314.1, // E
            1445.5  // F#
        ],
        // Bells Set 2 (dummy data)
        [
            1234,
            23.41,
            341.2,
            41.23
        ]
    ];

    // NOTE: Order of instruments must match position of items in instrument menu.

    var instruments = [
        // Bells
        {
			var sugs = [];
			2.do{
				var amp = 0.1;
				var t_trig = 1;
				var freq = current_pitch_set.choose;
				var dur = 0.2.exprand(3.0);
				var amps = #[1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33];
				var durs = #[1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075];
				var frqs = #[0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07];
				var dets = #[0, 1, 0, 1.7, 0, 0, 0, 0, 0, 0, 0];
				var src = Mix.fill(11, {|i|
					var env = EnvGen.ar(
						Env.perc(0.005, dur * durs[i], amps[i], -4.5),
						t_trig
					);
					SinOsc.ar(freq * frqs[i] + dets[i], 0, amp * env);
				});
				sugs = sugs.add(src);
			};
			Out.ar(0, Pan2.ar(Mix.new(sugs), 0));
        },
        // PIANO
        {
            var note_1 = OteyPianoStrings.ar(current_pitch_set.choose),
                note_2 = OteyPianoStrings.ar(current_pitch_set.choose);
            note_1 = RLPF.ar(note_1) * 0.5;
            note_2 = RLPF.ar(note_2) * 0.5;
            note_1 + note_2;
        }
    ];

    var current_pitch_set = pitch_sets[0];

    var current_instrument = instruments[0];

    SynthDef(\risset, {|out= 0, pan= 0, freq= 400, amp= 0.1, dur= 2, t_trig= 1|
        var amps= #[1, 0.67, 1, 1.8, 2.67, 1.67, 1.46, 1.33, 1.33, 1, 1.33];
        var durs= #[1, 0.9, 0.65, 0.55, 0.325, 0.35, 0.25, 0.2, 0.15, 0.1, 0.075];
        var frqs= #[0.56, 0.56, 0.92, 0.92, 1.19, 1.7, 2, 2.74, 3, 3.76, 4.07];
        var dets= #[0, 1, 0, 1.7, 0, 0, 0, 0, 0, 0, 0];
        var src= Mix.fill(11, {|i|
            var env = EnvGen.ar(
				Env.perc(0.005, dur*durs[i], amps[i], -4.5),
				t_trig
			);
            SinOsc.ar(freq*frqs[i]+dets[i], 0, amp*env);
        });
        Out.ar(out, Pan2.ar(src, pan));
    }).add;

	SynthDef(\help_oteypianostring, { |out=0, freq=440,gate=1, amp=0.5,rho=1|
		    var son = OteyPianoStrings.ar(freq, amp, rho:rho)*EnvGen.ar(Env.asr(0,1,0.1),gate,doneAction:2);
		    Out.ar(out, Pan2.ar(son * 1, LinLin.kr(freq,36.midicps,90.midicps,-0.75,0.75)));
	}).add;

	SynthDef(\piano_soundboard,{
		    var audio = In.ar([20, 21], 2);
		    audio = OteySoundBoard.ar(audio);
		    Out.ar(0,audio);
	}).add;

	Synth.tail(1,\piano_soundboard);

    // Q: Should we always choose two DIFFERENT random notes from set,
    //    or possibly two SAME random notes from set, at one time?

    ~w = Window("threshold setting", Rect(15, 100, 300, 150))
        .onClose_({
            ~ampSynth.free;
            ~ampUpdater.free;
            ~oscTrigResp.free;
            current_instrument.stop;
        });

    ~w.view.decorator = FlowLayout(~w.view.bounds, 2@2, 2@2);

    ~pitch_set_menu = PopUpMenu(~w, Rect(10, 10, 90, 20));
    ~pitch_set_menu.items_(["Bells 1", "Bells 2"]);
    ~pitch_set_menu.action = { arg menu;
        current_pitch_set = pitch_sets[menu.value];
        ("New pitch set for " + menu.item + ":").postln;
        current_pitch_set.postln;
    };

    ~instrument_set_menu = PopUpMenu(~w, Rect(10, 10, 90, 20));
    ~instrument_set_menu.items_(["Bell", "Piano"]);
    ~instrument_set_menu.action = { arg menu;
        current_instrument = instruments[menu.value];
        ("New instrumentfor " + menu.item + ":").postln;
        current_instrument.postln;
    };

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
        if(current_instrument.isNil or: { current_instrument.isPlaying.not }) {
            current_instrument.play;
        }
    }, '/amptrig', s.addr);

}
);
