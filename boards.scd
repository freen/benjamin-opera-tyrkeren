// Q: Which octave does Andrew mean?
// http://www.electronics.dit.ie/staff/tscarff/Music_technology/midi/midi_note_numbers_for_octaves.htm
// https://docs.google.com/document/d/1AdY8mYTAHoDBee3Zoc3bZJsfBM3h2q00d9FHBes0HoY/edit

// Q: Should we always choose two DIFFERENT random notes from set,
//    or possibly two SAME random notes from set, at one time?

// TODO:
// - Instrument sets will support per-mic instruments, e.g. var instrument_sets
// - Instruments which should play continuous notes, e.g. clarinet?

// If "address already in use"
Server.killAll;

var s,
    sixtyFourMb = 65536,
    inDeviceName = "DUO-CAPTURE EX 44.1kHz",
    outDeviceName = "Built-in Output";
// outDeviceName = "Soundcraft Signature 12 MTK",
// busBoard1 = 4,
// busBoard2 = 5,
// busBoard3 = 6,
// busBoard4 = 8,
// board1, board2, board3, board4;

s = Server.local;
s.options.memSize_(sixtyFourMb * 8);
s.options.inDevice_(inDeviceName);
s.options.outDevice_(outDeviceName);
s.options.numInputBusChannels_(2);
s.options.numOutputBusChannels_(2);
// s.options.numInputBusChannels_(14);
// s.options.numOutputBusChannels_(12);

(

s.waitForBoot{

    // Order of sets must match order of position in pitch set menu.

    ~pitch_sets = [
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

    ~bell = {
		var out = 0;
		var sugs = [];
		2.do{
			var amp = 0.1;
			var t_trig = 1;
			var freq = ~current_pitch_set.choose;
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
			var fullBellEnv = EnvGen.ar(
				Env.perc(0.005, 1, 1, -4),
				doneAction: 2
			);
			sugs = sugs.add(src * fullBellEnv);
		};
		Out.ar(out, Pan2.ar(Mix.new(sugs), 0));
	};

    ~piano = {
		2.do {
			var out = 0;
			var amp = 0.5;
			var rho = 1;
			var freq = ~current_pitch_set.choose;
			var gate = 1;
			var env = EnvGen.ar(
				Env.asr(0,1, 0.1),
				gate,
				doneAction: 2
			);
			var son = OteyPianoStrings.ar(freq, amp, rho:rho) * env;
			var fullMixEnv = EnvGen.ar(
				Env.perc(0.005, 5, 1),
				doneAction: 2
			);
			var fullMix = Pan2.ar(
				son * 1,
				LinLin.kr(freq, 36.midicps, 90.midicps, -0.75, 0.75)
			) * fullMixEnv;
			Out.ar(
				out,
				fullMix
			);
		};
	};

	~wave = {
		var gate = 1;
		Out.ar(
			0,
			EnvGen.ar(
				Env.asr(0, 1, 0.1),
				gate,
				doneAction: 2
			) * SinOsc.ar()
		);
	};

	// NOTE: Order of instrument_sets must match position of items in instrument sets menu.

	~input_channels = [
		0,
		1
	];

	// Indices of instruments in instrument sets map to indices of input_channels
	~instrument_sets = [
		[~piano, ~wave],
		[~bell, ~wave],
		[~piano, ~bell]
	];

    ~current_pitch_set = ~pitch_sets[0];

    ~current_instrument_set = ~instrument_sets[0];

	~ampViews = [];
    ~decayViews = [];
	~threshViews = [];
	~ampSynths = [];
	~ampUpdaters = [];
	~oscTrigResponses = [];

	SynthDef(\piano_soundboard,{
		    var audio = In.ar([20, 21], 2);
		    audio = OteySoundBoard.ar(audio);
		    Out.ar(0,audio);
	}).add;

	SynthDef(\ampSynth, { |inbus, thresh = 0.8, decay = 1|
		var amp = Amplitude.kr(In.ar(inbus, 1), attackTime: 0.01, releaseTime: decay);
		//var amp = Amplitude.kr(SoundIn.ar(inbus), attackTime: 0.01, releaseTime: decay);
		// this trigger (id==0) is to update the gui only
		SendReply.kr(Impulse.kr(10), '/amp', amp);
		// this trigger gets sent only when amplitude crosses threshold
		SendReply.kr(amp >= thresh, '/amptrig');
	}).add;

	Synth.tail(1, \piano_soundboard);

    ~w = Window("threshold setting", Rect(15, 100, 300, 300))
        .onClose_({
            ~ampSynth.free;
            ~ampUpdater.free;
            ~oscTrigResp.free;
            ~current_instrument.stop;
        });

    ~w.view.decorator = FlowLayout(~w.view.bounds, 2@2, 2@2);

    ~pitch_set_menu = PopUpMenu(~w, Rect(10, 10, 90, 20));
    ~pitch_set_menu.items_(["Bells 1", "Bells 2"]);
    ~pitch_set_menu.action = { arg menu;
        ~current_pitch_set = ~pitch_sets[menu.value];
        ("New pitch set for " + menu.item + ":").postln;
        ~current_pitch_set.postln;
    };

    ~instrument_set_menu = PopUpMenu(~w, Rect(10, 10, 90, 20));
    ~instrument_set_menu.items_(["Bell", "Piano"]);
    ~instrument_set_menu.action = { arg menu;
        ~current_instrument_set = ~instrument_sets[menu.value];
        ("New instrument set for " + menu.item + ":").postln;
        ~current_instrument_set.postln;
    };

	~input_channels.do({ arg input_channel, i;

		~ampView = EZSlider(~w, 295@20, "amplitude", \amp, labelWidth: 80, numberWidth: 60);
		~ampView.sliderView.canFocus_(false).enabled_(false);
		~ampView.numberView.canFocus_(false).enabled_(false);

		~ampViews = ~ampViews.add(~ampView);

		StaticText(~w, 295@5).background_(Color.gray);

		~threshView = EZSlider(~w, 295@30, "threshold", \amp, action: { |ez|
			~ampSynths[i].set(\thresh, ez.value);
		}, initVal: 0.4, labelWidth: 80, numberWidth: 60);

		~threshViews = ~threshViews.add(~threshView);

		~ampSynth = Synth.new(\ampSynth, [inbus: input_channel, thresh: ~threshViews[i].value, decay: ~decayViews[i].value]);

		~ampSynths = ~ampSynths.add(~ampSynth);

		~decayView = EZSlider(~w, 295@30, "decay", #[0.1, 100, \exp], action: { |ez|
			~ampSynths[i].set(\decay, ez.value);
		}, initVal: 80.0, labelWidth: 80, numberWidth: 60);

		~decayViews = ~decayViews.add(~decayView);

		~ampUpdater = OSCFunc({ |msg|
			defer { ~ampViews[i].value = msg[3] }
		}, '/amp', s.addr);

		~ampUpdaters = ~ampUpdaters.add(~ampUpdater);

		~oscTrigResp = OSCFunc({ |msg|
			~current_instrument = ~current_instrument_set[i];
			if(~current_instrument.isNil or: { ~current_instrument.isPlaying.not }) {
				~current_instrument.play;
			}
		}, '/amptrig', s.addr);

		~oscTrigResponses.add(~oscTrigResp);

		StaticText(~w, 295@5).background_(Color.gray);

	});

    ~w.front;

}
);
