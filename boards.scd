// Q: Which octave does Andrew mean?
// http://www.electronics.dit.ie/staff/tscarff/Music_technology/midi/midi_note_numbers_for_octaves.htm
// https://docs.google.com/document/d/1AdY8mYTAHoDBee3Zoc3bZJsfBM3h2q00d9FHBes0HoY/edit

// Q: Should we always choose two DIFFERENT random notes from set,
//	or possibly two SAME random notes from set, at one time?

// TODO:
// - Instrument sets will support per-mic instruments, e.g. var instrument_sets
// - Instruments which should play continuous notes, e.g. clarinet?

// If "address already in use"
Server.killAll;

(

~thresholdInitValue = 0.02;
~decayInitValue = 0.33;
~outputChannel = 5;

Server.quitAll;

s = Server.local;
s.options.memSize_(65536 * 8); // 64 MB * 8
// s.options.inDevice_("DUO-CAPTURE EX 44.1kHz")
s.options.inDevice_("Soundcraft Signature 12 MTK");
// s.options.inDevice_("Built-in Microph");
s.options.outDevice_("Soundcraft Signature 12 MTK");
// s.options.outDevice_("Built-in Output");
s.options.numInputBusChannels_(14);
s.options.numOutputBusChannels_(12);
// s.options.numInputBusChannels_(2);
// s.options.numOutputBusChannels_(2);

s.reboot;

s.waitForBoot{

	// Order of sets must match order of position in pitch set menu.

	~pitch_sets = [
		// Set 1: Bells
		[
			65.7, 73.75,
			82.7, 92.9,
			110.5,
			124.0,
			131.41,
			147.5,
			165.5,
			185.8,
			221,
			248,
			242.8,
			295,
			331.1,
			371.6,
			442,
			496.1,
			590,
			662.25,
			743.3,
			884,
			992.2
		],
		// Set 2: Bells
		[
			78.1, 87.7, 98.4, 131.4, 147.5, 156.7, 175.4, 196.8, 262.8, 295, 312.5, 350.8, 394.7, 525.6, 590,
			701.6, 787.5, 1051.25, 1180
		],
		// Set 3
		[
			73.7, 147.5, 295, 590, 1180,
			92.9, 185.8, 371.6, 743.3,
			110.5, 221, 442, 884
		],
		// Set 4
		[
			87.7, 175.4, 350.8, 701.6,
			104.3, 208.6, 417.1, 834.3,
			65.7, 131.4, 262.1, 525.6, 1051.2
		],
		// Set 5
		[
			62, 124, 248,
			156.2, 312.5, 625,
			468.2, 936.5, 1873.1
		],
		// Set 6
		[
			78, 156, 312, 625, // Eb
			295, 590, 1180, // D
			442, 884, 1768 // A
		],
		// Set 7
		[
			248, 964, // B
			331, 662, // E
			701, 1403, // F
			963, 1873 // Bb
		],
		// Set 8
		[
			82.7, 165.5, 331.1, 662.2, 117, 234.1, 468.2, 936.5, 73.7, 147.5, 295, 590, 1180
		],
		// Set 9
		[
			65, 131, 262, 525,
			165, 331, 662, 1324,
			234, 468, 936
		],
		// Set 10
		[
			82, 165, 331, 662,
			208, 417, 834, 1668,
			496, 992
		],
		// Set 11
		[
			82, 165, 331, 662,
			787, 1575,
			496, 992
		],
		// Set 12
		[
			147, 295, 590,
			371, 743, 1486,
			442, 884, 1768,
			496, 992,
			556, 1113
		]
	];

	~risset_bell = {
		var out = 0;
		var sugs = [];
		1.do{
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

	~prayer_bell = {
		1.do {
			var gate = 1;
			var env = EnvGen.ar(
				Env.perc(0.005, 1, 0.1),
				doneAction: 2
			);
			var sug = Synth.new(\prayer_bell, [
				\freq, ~current_pitch_set.choose,
				\lag, 3,
				\i_doneAction, 2,
				\outbus, ~outputChannel
			]);
			Out.ar(~outputChannel, sug);
		};
	};

	~piano = {
		2.do {
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
				~outputChannel,
				fullMix
			);
		};
	};

	~deer_scare = {
		var gate = 1;
		var buf = Buffer.read(s, "/Users/freen/src/benjamin-opera-tyrkeren/a_rook_is_placed.wav");
		var sig = PlayBuf.ar(2, buf, BufRateScale.kr(buf), doneAction: 2);
		var env = EnvGen.ar(
			Env.perc(0.005, 1, 0.1),
			doneAction: 2
		);

		sig = FreqShift.ar(sig, 900);
		sig = RHPF.ar(sig, 900);
		sig = LeakDC.ar(sig);

		sig = Compander.ar(sig, sig,
			thresh: 0.1,
			slopeBelow: 10,
			slopeAbove: 1,
			clampTime: 0.01,
			relaxTime: 0.01
		);

		Out.ar(~outputChannel, sig * env);
	};

	~wavy_xmission = {
		var sig, env;
		sig = SinOsc.ar([300, 500, 800, 1000]);
		sig = FreeVerb.ar(sig, room:0.8) * 5;
		sig = DelayN.ar(sig, 0.048);
		sig = Compander.ar(sig, sig,
			thresh: 0.013,
			slopeBelow: 10,
			slopeAbove: 1,
			clampTime: 0.01,
			relaxTime: 0.01
		);
		sig = DelayN.ar(sig, 0.048);
		sig = BPF.ar(sig);

		sig = MoogFF.ar(
			sig,
			SinOsc.kr(LFNoise0.kr(0.42).range(0.001, 2.2)).range(30, 4200),
			0.83 * 4
		);
		env = EnvGen.ar(
			Env.perc(0.005, 1, 0.1),
			doneAction: 2
		);
		Out.ar(~outputChannel, sig * env);
	};

	~strings = {
		var env, in, delay, f1, f2, sug;
		var out = 0, freq = ~current_pitch_set.choose, amp=1, gate=1, pan=1, freqLag=0;
		f1 = freq.lag(freqLag);
		f2 = freq.lag(freqLag * 0.5);
		delay = 0.25 / f2;
		env = Env.asr(0, 1, 0.3);
		in = WhiteNoise.ar(180);
		in = CombL.ar(in, delay, delay, 1);
		in = Resonz.ar(in, f1, 0.001).abs;
		in = in * EnvGen.kr(env, gate, doneAction:2);
		sug = Pan2.ar(in, pan, amp) * EnvGen.ar(
			Env.perc(releaseTime: 4), doneAction: 2
		);
		Out.ar(~outputChannel, sug ! 2);
	};

	// NOTE: Order of instrument_sets must match position of items in instrument sets menu.

	~input_channels = [
		0,
		1,
		2,
		3
	];

	// Indices of instruments in instrument sets map to indices of input_channels
	~instrument_sets = [
		[
			~prayer_bell,
			~prayer_bell,
			~prayer_bell,
			~prayer_bell
		],
		[
			~piano,
			// ~strings,
			~piano,
			~piano,
			~piano
			// ~strings
		],
		[
			~wavy_xmission,
			~deer_scare,
			~deer_scare,
			~wavy_xmission
		]
	];

	~current_pitch_set = ~pitch_sets[0];

	~current_instrument_set = ~instrument_sets[0];

	~ampViews = [];
	~decayViews = [];
	~threshViews = [];
	~ampSynths = [];

	SynthDef(\prayer_bell, { |outbus, t_trig = 1, sing_switch = 0, freq = 2434, amp = 0.5, decayscale = 1, lag = 10, i_doneAction = 0|
		var fullEnv, sig, input, first, freqscale, mallet, sing;
		freqscale = freq / 2434;
		freqscale = Lag3.kr(freqscale, lag);
		decayscale = Lag3.kr(decayscale, lag);

		mallet = LPF.ar(Trig.ar(t_trig, SampleDur.ir)!2, 10000 * freqscale);
		sing = LPF.ar(
		LPF.ar(
			{
			PinkNoise.ar * Integrator.kr(sing_switch * 0.001, 0.999).linexp(0, 1, 0.01, 1) * amp
			} ! 2,
			2434 * freqscale
		) + Dust.ar(0.1), 10000 * freqscale
		) * LFNoise1.kr(0.5).range(-45, -30).dbamp;
		input = mallet + (sing_switch.clip(0, 1) * sing);

		sig = DynKlank.ar(`[
		[
			(first = LFNoise1.kr(0.5).range(2424, 2444)) + Line.kr(20, 0, 0.5),
			first + LFNoise1.kr(0.5).range(1,3),
			LFNoise1.kr(1.5).range(5435, 5440) - Line.kr(35, 0, 1),
			LFNoise1.kr(1.5).range(5480, 5485) - Line.kr(10, 0, 0.5),
			LFNoise1.kr(2).range(8435, 8445) + Line.kr(15, 0, 0.05),
			LFNoise1.kr(2).range(8665, 8670),
			LFNoise1.kr(2).range(8704, 8709),
			LFNoise1.kr(2).range(8807, 8817),
			LFNoise1.kr(2).range(9570, 9607),
			LFNoise1.kr(2).range(10567, 10572) - Line.kr(20, 0, 0.05),
			LFNoise1.kr(2).range(10627, 10636) + Line.kr(35, 0, 0.05),
			LFNoise1.kr(2).range(14689, 14697) - Line.kr(10, 0, 0.05)
		],
		[
			LFNoise1.kr(1).range(-10, -5).dbamp,
			LFNoise1.kr(1).range(-20, -10).dbamp,
			LFNoise1.kr(1).range(-12, -6).dbamp,
			LFNoise1.kr(1).range(-12, -6).dbamp,
			-20.dbamp,
			-20.dbamp,
			-20.dbamp,
			-25.dbamp,
			-10.dbamp,
			-20.dbamp,
			-20.dbamp,
			-25.dbamp
		],
		[
			20 * freqscale.pow(0.2),
			20 * freqscale.pow(0.2),
			5,
			5,
			0.6,
			0.5,
			0.3,
			0.25,
			0.4,
			0.5,
			0.4,
			0.6
		] * freqscale.reciprocal.pow(0.5)
		], input, freqscale, 0, decayscale);

		DetectSilence.ar(sig, doneAction: i_doneAction);

		fullEnv = EnvGen.ar(Env.asr(releaseTime: 5), doneAction: 2);

		Out.ar(outbus, sig * fullEnv);
	}).add;

	SynthDef(\piano_soundboard,{
		var audio = In.ar([20, 21], 2);
		audio = OteySoundBoard.ar(audio);
		Out.ar(~outputChannel, audio);
	}).add;

	SynthDef(\ampSynth, { |input_channel, thresh = 0.8, decay = 1|
		var amp = Amplitude.kr(SoundIn.ar(input_channel), attackTime: 0.01, releaseTime: decay);
		SendReply.kr(Impulse.kr(10), '/amp', amp, input_channel);
		SendReply.kr(amp >= thresh, '/amptrig', replyID: input_channel);
	}).add;

	SynthDef(\sax, { |out, freq=440, amp=0.1, gate=1|
		var num = 16;
		var harms = Array.series(num, 1, 1) * Array.exprand(num, 0.995, 1.001);
		var snd = SinOsc.ar(freq * SinOsc.kr(Rand(2.0,5.0),0,Rand(0.001, 0.01),1) * harms, mul:Array.geom(num, 1, 0.63));
		snd = Splay.ar(snd);
		snd = BBandPass.ar(snd, freq * XLine.kr(0.1,4,0.01), 2);
		snd = snd * amp * EnvGen.ar(Env.adsr(0.001, 0.2, 0.7, 0.2), gate, doneAction:2);
		Out.ar(out, snd!2);
	}).add;

	// SynthDef(\chorus, { arg inbus=2, outbus=6, predelay=0.08, speed=0.05, depth=0.1, ph_diff=0.5;
	// 	var in, sig, modulators, numDelays = 12;
	// 	in = SoundIn.ar(inbus, 1) * numDelays.reciprocal;
	//
	// 	// in = SoundIn.ar(inbus) * numDelays.reciprocal;
	// 	modulators = Array.fill(numDelays, {arg i;
	// 	LFPar.kr(speed * rrand(0.94, 1.06), ph_diff * i, depth, predelay);});
	// 	sig = DelayC.ar(in, 0.5, modulators, mul: 12);
	// 	sig = sig.sum;
	// 	sig = sig * 2;
	// 	Out.ar(outbus, sig ! 2); // output in stereo
	// }).add;
	//
	// {
	// 	Out.ar(6, SoundIn.ar(2))
	// }.play(addAction:\addToHead);
	//
	// a = Synth(\chorus, addAction:\addToTail);
	// a.set(\predelay, 0.02);
	// a.set(\speed, 0.22);
	// a.set(\depth, 0.5);
	// a.set(\pd_diff, 0.7);
	// a.set(\predelay, 0.2);

	Synth.tail(1, \piano_soundboard);

	~w = Window("BENJAMIN OPERA TYRKEREN", Rect(15, 100, 300, 440))
		.onClose_({
			~ampSynths.do({ arg ampSynth, i; ampSynth.free; });
			~ampUpdater.free;
			~oscTrigResp.free;
		});

	~w.view.decorator = FlowLayout(~w.view.bounds, 2@2, 2@2);

	~pitch_set_menu = PopUpMenu(~w, Rect(10, 10, 90, 20));
	~pitch_set_menu.items_(
		[
			"Set 1: Bells",
			"Set 2: Bells",
			"Set 3",
			"Set 4",
			"Set 5",
			"Set 6",
			"Set 7",
			"Set 8",
			"Set 9",
			"Set 10",
			"Set 11",
			"Set 12",
			"Set 13"
		]
	);
	~pitch_set_menu.action = { arg menu;
		~current_pitch_set = ~pitch_sets[menu.value];
		("New pitch set for " + menu.item + ":").postln;
		~current_pitch_set.postln;
	};

	~instrument_set_menu = PopUpMenu(~w, Rect(10, 10, 90, 20));
	~instrument_set_menu.items_(
		[
			"Bells, Bells, Bells, Bells",
			"Piano, Piano, Piano, Piano",
			"Pitchless"
		]
	);
	~instrument_set_menu.action = { arg menu;
		~current_instrument_set = ~instrument_sets[menu.value];
		("New instrument set for " + menu.item + ":").postln;
		~current_instrument_set.postln;
	};

	~input_channels.do({ arg input_channel, i;

		"Input Channel %: Building GUI and amp / thresh synths".format(input_channel).postln;

		~ampView = EZSlider(~w, 295@20, "amplitude", \amp, labelWidth: 80, numberWidth: 60);
		~ampView.sliderView.canFocus_(false).enabled_(false);
		~ampView.numberView.canFocus_(false).enabled_(false);

		~ampViews = ~ampViews.add(~ampView);

		StaticText(~w, 295@5).background_(Color.gray);

		~threshView = EZSlider(~w, 295@30, "threshold", \amp, action: { |ez|
			~ampSynths[i].set(\thresh, ez.value);
		}, initVal: ~thresholdInitValue, labelWidth: 80, numberWidth: 60);

		~threshViews = ~threshViews.add(~threshView);

		~ampSynth = Synth.new(\ampSynth, [input_channel: input_channel, thresh: ~threshViews[i].value, decay: ~decayViews[i].value]);

		~ampSynths = ~ampSynths.add(~ampSynth);

		~decayView = EZSlider(~w, 295@30, "decay", #[0.1, 100, \exp], action: { |ez|
			~ampSynths[i].set(\decay, ez.value);
		}, initVal: ~decayInitValue, labelWidth: 80, numberWidth: 60);

		~decayViews = ~decayViews.add(~decayView);

		StaticText(~w, 295@5).background_(Color.gray);

	});

	~ampUpdater = OSCFunc({ |msg|
		// "ampUpdater: %".format(msg).postln;
		defer {
			~ampViews[msg[2]].value = msg[3]
		}
	}, '/amp', s.addr);

	~oscTrigResp = OSCFunc({ |msg|
		var input_channel = msg[2];
		"Received oscTrigResp on channel %: %".format(input_channel, msg).postln;
		~current_instrument = ~current_instrument_set[input_channel];
		~current_instrument.play;
	}, '/amptrig', s.addr);

	~w.front;
}
);
