// Q: which octave does Andrew mean?
// http://www.electronics.dit.ie/staff/tscarff/Music_technology/midi/midi_note_numbers_for_octaves.htm
// https://docs.google.com/document/d/1AdY8mYTAHoDBee3Zoc3bZJsfBM3h2q00d9FHBes0HoY/edit

48.midicps;

(

(

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

var BELLS_NOTES_SET = [
	131.41, // C
	156.27, // D
	662.25, // E
	884,    // A
	992.3,  // B
	1314.1, // E
	1445.5  // F#
];

var pattern = Pbind(
        \degree, Pseries(7, Pwhite(1, 3, inf) * Prand(#[-1, 1], inf), inf).fold(0, 14)
            + Prand(#[[0, -2, -4], [0, -3, -5], [0, -2, -5], [0, -1, -4]], inf),
        \dur, Pwrand(#[1, 0.5], #[0.8, 0.2], inf)
    ),
    player;

// Quicky GUI to tune threshold and decay times
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
    var    amp = Amplitude.kr(In.ar(inbus, 1), attackTime: 0.01, releaseTime: decay);
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
		player = {
			var note_1 = OteyPianoStrings.ar(Rand(80, 600)),
			    note_2 = OteyPianoStrings.ar(Rand(80, 600));
			note_1 = RLPF.ar(note_1) * 0.5;
			note_2 = RLPF.ar(note_2) * 0.5;
			note_1 + note_2;
		}.play;
    } {
        player.stop;
    };
}, '/amptrig', s.addr);
)
)