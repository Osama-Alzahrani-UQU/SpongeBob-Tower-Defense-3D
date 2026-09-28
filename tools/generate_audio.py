import os
import wave
import struct
import numpy as np

SAMPLE_RATE = 44100

def note_freq(midi_note):
    return 440.0 * (2.0 ** ((midi_note - 69) / 12.0))

def save_wav(filepath, audio_data, sample_rate=SAMPLE_RATE, target_peak=0.65):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    # Ensure float32 in range [-1.0, 1.0] with natural musical headroom
    max_val = np.max(np.abs(audio_data))
    if max_val > 0.0001:
        audio_data = audio_data / max_val * target_peak
    else:
        audio_data = np.zeros_like(audio_data)
        
    int16_data = (np.clip(audio_data, -0.98, 0.98) * 32767.0).astype(np.int16)
    with wave.open(filepath, 'wb') as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(sample_rate)
        wf.writeframes(int16_data.tobytes())
    print(f"Generated: {os.path.basename(filepath)} ({len(audio_data)/sample_rate:.2f}s, peak={target_peak:.2f})")

def apply_lowpass(audio, cutoff_freq=2400.0, sample_rate=SAMPLE_RATE):
    rc = 1.0 / (2.0 * np.pi * cutoff_freq)
    dt = 1.0 / sample_rate
    alpha = dt / (rc + dt)
    out = np.zeros_like(audio)
    val = 0.0
    for i in range(len(audio)):
        val += alpha * (audio[i] - val)
        out[i] = val
    val = 0.0
    for i in range(len(audio) - 1, -1, -1):
        val += alpha * (out[i] - val)
        out[i] = val
    return out

# -------------------------------------------------------------
# Instrument Synthesizers
# -------------------------------------------------------------

def synth_marimba_lead(notes_with_times, total_duration):
    # Soft, warm wooden marimba / vibraphone lead (authentic relaxing island acoustic)
    total_len = int(SAMPLE_RATE * total_duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    for start_t, dur, midi in notes_with_times:
        start_idx = int(start_t * SAMPLE_RATE)
        note_len = int(dur * SAMPLE_RATE)
        if start_idx + note_len > total_len:
            note_len = total_len - start_idx
        if note_len <= 0:
            continue
            
        t = np.linspace(0, note_len / SAMPLE_RATE, note_len, False)
        f0 = note_freq(midi)
        
        # Mellow wooden marimba mallet strike
        decay = np.exp(-t * (5.5 + (midi - 50) * 0.06))
        wave = (
            1.00 * np.sin(2 * np.pi * f0 * t) +
            0.18 * np.sin(2 * np.pi * 3.92 * f0 * t) * np.exp(-t * 22.0) +
            0.06 * np.sin(2 * np.pi * 2.0 * f0 * t) * np.exp(-t * 16.0)
        )
        # Soft mallet attack
        att_len = int(min(0.008 * SAMPLE_RATE, note_len * 0.1))
        env = np.ones(note_len, dtype=np.float32)
        if att_len > 0:
            env[:att_len] = np.linspace(0, 1, att_len)
            
        output[start_idx:start_idx+note_len] += wave * decay * env * 0.50
    return output

def synth_ukulele_chord(chord_notes, duration, strum_speed=0.025):
    # chord_notes: list of midi notes e.g. [60, 64, 67, 72]
    total_len = int(SAMPLE_RATE * duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    for i, note in enumerate(chord_notes):
        f = note_freq(note)
        delay = int(i * strum_speed * SAMPLE_RATE)
        rem_len = total_len - delay
        if rem_len <= 0:
            continue
        t = np.linspace(0, rem_len / SAMPLE_RATE, rem_len, False)
        # Pluck decay: fundamental + harmonics with rapid harmonic falloff
        decay = np.exp(-t * (4.5 + (note - 50) * 0.1))
        harmonics = (
            1.00 * np.sin(2 * np.pi * f * t) +
            0.55 * np.sin(2 * np.pi * 2 * f * t) * np.exp(-t * 8.0) +
            0.28 * np.sin(2 * np.pi * 3 * f * t) * np.exp(-t * 14.0) +
            0.15 * np.sin(2 * np.pi * 4 * f * t) * np.exp(-t * 22.0)
        )
        pluck = harmonics * decay
        output[delay:delay+rem_len] += pluck * 0.28
    return output

def synth_hawaiian_slide_lead(notes_with_times, total_duration):
    # notes_with_times: list of (start_t, dur, midi_from, midi_to, vibrato_amt)
    total_len = int(SAMPLE_RATE * total_duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    for start_t, dur, m_from, m_to, vib_amt in notes_with_times:
        start_idx = int(start_t * SAMPLE_RATE)
        note_len = int(dur * SAMPLE_RATE)
        if start_idx + note_len > total_len:
            note_len = total_len - start_idx
        if note_len <= 0:
            continue
            
        t = np.linspace(0, note_len / SAMPLE_RATE, note_len, False)
        # Smooth pitch slide
        f_start = note_freq(m_from)
        f_end = note_freq(m_to)
        slide_curve = 1.0 / (1.0 + np.exp(-t * 18.0 / max(0.05, dur)))
        freq = f_start + (f_end - f_start) * slide_curve
        
        # Vibrato after attack
        vib_envelope = np.clip((t - 0.12) * 3.5, 0.0, 1.0)
        vib = np.sin(2 * np.pi * 5.5 * t) * vib_amt * vib_envelope
        freq = freq * (1.0 + vib)
        
        phase = np.cumsum(2 * np.pi * freq / SAMPLE_RATE)
        # Warm lap steel timbre (odd & even harmonics with warm chorus)
        wave = (
            0.85 * np.sin(phase) +
            0.45 * np.sin(phase * 2.0) +
            0.25 * np.sin(phase * 3.0) +
            0.12 * np.sin(phase * 4.0)
        )
        # Envelope: soft attack, singing sustain, gentle release
        env = np.ones(note_len, dtype=np.float32)
        att_len = int(0.04 * SAMPLE_RATE)
        rel_len = int(0.10 * SAMPLE_RATE)
        if att_len < note_len:
            env[:att_len] = np.linspace(0, 1, att_len)
        if rel_len < note_len:
            env[-rel_len:] = np.linspace(1, 0, rel_len)
            
        output[start_idx:start_idx+note_len] += wave * env * 0.40
    return output

def synth_accordion_lead(notes_with_times, total_duration):
    # notes_with_times: list of (start_t, dur, midi_note)
    total_len = int(SAMPLE_RATE * total_duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    for start_t, dur, midi in notes_with_times:
        start_idx = int(start_t * SAMPLE_RATE)
        note_len = int(dur * SAMPLE_RATE)
        if start_idx + note_len > total_len:
            note_len = total_len - start_idx
        if note_len <= 0:
            continue
            
        t = np.linspace(0, note_len / SAMPLE_RATE, note_len, False)
        f0 = note_freq(midi)
        # Dual detuned reeds (tremolo beating at 2.2 Hz)
        reed1 = np.sin(2 * np.pi * f0 * t) + 0.35 * np.sin(2 * np.pi * 2 * f0 * t) + 0.20 * np.sin(2 * np.pi * 3 * f0 * t)
        reed2 = np.sin(2 * np.pi * (f0 + 1.8) * t) + 0.35 * np.sin(2 * np.pi * 2 * (f0 + 1.8) * t) + 0.20 * np.sin(2 * np.pi * 3 * (f0 + 1.8) * t)
        wave = 0.5 * (reed1 + reed2)
        
        env = np.ones(note_len, dtype=np.float32)
        att_len = int(min(0.03 * SAMPLE_RATE, note_len * 0.2))
        rel_len = int(min(0.06 * SAMPLE_RATE, note_len * 0.3))
        if att_len > 0:
            env[:att_len] = np.linspace(0, 1, att_len)
        if rel_len > 0:
            env[-rel_len:] = np.linspace(1, 0, rel_len)
            
        output[start_idx:start_idx+note_len] += wave * env * 0.35
    return output

def synth_clarinet_lead(notes_with_times, total_duration):
    total_len = int(SAMPLE_RATE * total_duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    for start_t, dur, midi in notes_with_times:
        start_idx = int(start_t * SAMPLE_RATE)
        note_len = int(dur * SAMPLE_RATE)
        if start_idx + note_len > total_len:
            note_len = total_len - start_idx
        if note_len <= 0:
            continue
            
        t = np.linspace(0, note_len / SAMPLE_RATE, note_len, False)
        f0 = note_freq(midi)
        # Vibrato
        vib = 1.0 + 0.015 * np.sin(2 * np.pi * 4.8 * t)
        phase = np.cumsum(2 * np.pi * f0 * vib / SAMPLE_RATE)
        # Clarinet signature: prominent odd harmonics (1, 3, 5, 7)
        wave = (
            0.90 * np.sin(phase) +
            0.12 * np.sin(phase * 2.0) +
            0.55 * np.sin(phase * 3.0) +
            0.08 * np.sin(phase * 4.0) +
            0.35 * np.sin(phase * 5.0) +
            0.18 * np.sin(phase * 7.0)
        )
        # Soft breath noise
        breath = (np.random.rand(note_len) * 2 - 1) * 0.04 * np.exp(-t * 6.0)
        
        env = np.ones(note_len, dtype=np.float32)
        att_len = int(min(0.05 * SAMPLE_RATE, note_len * 0.25))
        rel_len = int(min(0.08 * SAMPLE_RATE, note_len * 0.3))
        if att_len > 0:
            env[:att_len] = np.linspace(0, 1, att_len)
        if rel_len > 0:
            env[-rel_len:] = np.linspace(1, 0, rel_len)
            
        output[start_idx:start_idx+note_len] += (wave + breath) * env * 0.38
    return output

def synth_surf_guitar_lead(notes_with_times, total_duration):
    total_len = int(SAMPLE_RATE * total_duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    for start_t, dur, midi in notes_with_times:
        start_idx = int(start_t * SAMPLE_RATE)
        note_len = int(dur * SAMPLE_RATE)
        if start_idx + note_len > total_len:
            note_len = total_len - start_idx
        if note_len <= 0:
            continue
            
        t = np.linspace(0, note_len / SAMPLE_RATE, note_len, False)
        f0 = note_freq(midi)
        phase = 2 * np.pi * f0 * t
        # Twangy single-coil pickup tone with rich harmonics
        wave = (
            0.95 * np.sin(phase) +
            0.60 * np.sin(phase * 2.0) +
            0.40 * np.sin(phase * 3.0) +
            0.25 * np.sin(phase * 4.0) +
            0.15 * np.sin(phase * 5.0)
        )
        # Slight overdrive saturation
        wave = np.tanh(wave * 1.6)
        
        # Pluck decay envelope
        decay = np.exp(-t * 5.2)
        pluck = wave * decay
        
        # Spring reverb emulation (slapback delay with decay)
        delay_samples = int(0.042 * SAMPLE_RATE)
        wet = np.zeros(note_len, dtype=np.float32)
        if note_len > delay_samples:
            wet[delay_samples:] = pluck[:-delay_samples] * 0.45
            
        output[start_idx:start_idx+note_len] += (pluck + wet) * 0.36
    return output

def synth_bassline(notes_with_times, total_duration, instrument="acoustic"):
    total_len = int(SAMPLE_RATE * total_duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    for start_t, dur, midi in notes_with_times:
        start_idx = int(start_t * SAMPLE_RATE)
        note_len = int(dur * SAMPLE_RATE)
        if start_idx + note_len > total_len:
            note_len = total_len - start_idx
        if note_len <= 0:
            continue
            
        t = np.linspace(0, note_len / SAMPLE_RATE, note_len, False)
        f0 = note_freq(midi)
        phase = 2 * np.pi * f0 * t
        
        if instrument == "synth":
            # Punchy synth bass (Jellyfish Jam style)
            wave = (
                0.90 * np.sin(phase) +
                0.65 * np.sign(np.sin(phase)) * 0.4 +
                0.35 * np.sin(phase * 2.0)
            )
            decay = np.exp(-t * 6.5)
        elif instrument == "tuba":
            # Bouncy brass tuba
            wave = (
                0.90 * np.sin(phase) +
                0.50 * np.sin(phase * 2.0) +
                0.25 * np.sin(phase * 3.0)
            )
            decay = np.exp(-t * 4.5)
        else:
            # Warm acoustic upright bass
            wave = (
                1.00 * np.sin(phase) +
                0.40 * np.sin(phase * 2.0) +
                0.15 * np.sin(phase * 3.0)
            )
            decay = np.exp(-t * 4.0)
            
        output[start_idx:start_idx+note_len] += wave * decay * 0.42
    return output

def synth_percussion_track(pattern_name, total_duration, bpm=120):
    total_len = int(SAMPLE_RATE * total_duration)
    output = np.zeros(total_len, dtype=np.float32)
    
    beat_dur = 60.0 / bpm
    total_beats = int(total_duration / beat_dur)
    
    for beat in range(total_beats):
        t_beat = beat * beat_dur
        b_idx = int(t_beat * SAMPLE_RATE)
        
        if pattern_name == "tropical":
            # Kick/coconut on 1 & 3, shaker on 2 & 4 + 8th notes
            if beat % 2 == 0:
                # Coconut / soft low tap
                hit_len = int(0.08 * SAMPLE_RATE)
                if b_idx + hit_len <= total_len:
                    t = np.linspace(0, 0.08, hit_len, False)
                    sweep = 140.0 * np.exp(-t * 35.0) + 55.0
                    phase = np.cumsum(2 * np.pi * sweep / SAMPLE_RATE)
                    output[b_idx:b_idx+hit_len] += np.sin(phase) * np.exp(-t * 28.0) * 0.32
            # Shaker on every 8th note
            for sub in [0.0, 0.5]:
                s_idx = int((t_beat + sub * beat_dur) * SAMPLE_RATE)
                s_len = int(0.05 * SAMPLE_RATE)
                if s_idx + s_len <= total_len:
                    noise = (np.random.rand(s_len) * 2 - 1)
                    t_sh = np.linspace(0, 0.05, s_len, False)
                    output[s_idx:s_idx+s_len] += noise * np.exp(-t_sh * 65.0) * 0.15
                    
        elif pattern_name == "polka":
            # Snappy polka kick on 1, snare rimshot on 2
            if beat % 2 == 0:
                # Bass kick
                hit_len = int(0.10 * SAMPLE_RATE)
                if b_idx + hit_len <= total_len:
                    t = np.linspace(0, 0.10, hit_len, False)
                    sweep = 160.0 * np.exp(-t * 40.0) + 50.0
                    phase = np.cumsum(2 * np.pi * sweep / SAMPLE_RATE)
                    output[b_idx:b_idx+hit_len] += np.sin(phase) * np.exp(-t * 30.0) * 0.35
            else:
                # Woodblock / rimshot clack
                hit_len = int(0.06 * SAMPLE_RATE)
                if b_idx + hit_len <= total_len:
                    t = np.linspace(0, 0.06, hit_len, False)
                    clack = np.sin(2 * np.pi * 920.0 * t) * np.exp(-t * 70.0)
                    noise = (np.random.rand(hit_len) * 2 - 1) * np.exp(-t * 50.0) * 0.3
                    output[b_idx:b_idx+hit_len] += (clack + noise) * 0.30
                    
        elif pattern_name == "surf_rock":
            # Driving rock beat: Kick on 1 and 3, Snare on 2 and 4, riding hi-hat
            if beat % 2 == 0:
                # Kick
                hit_len = int(0.12 * SAMPLE_RATE)
                if b_idx + hit_len <= total_len:
                    t = np.linspace(0, 0.12, hit_len, False)
                    sweep = 180.0 * np.exp(-t * 45.0) + 48.0
                    output[b_idx:b_idx+hit_len] += np.sin(np.cumsum(2*np.pi*sweep/SAMPLE_RATE)) * np.exp(-t*26.0) * 0.40
            else:
                # Snare
                hit_len = int(0.14 * SAMPLE_RATE)
                if b_idx + hit_len <= total_len:
                    t = np.linspace(0, 0.14, hit_len, False)
                    tone = np.sin(2 * np.pi * 210.0 * t) * np.exp(-t * 35.0)
                    noise = (np.random.rand(hit_len) * 2 - 1) * np.exp(-t * 30.0)
                    output[b_idx:b_idx+hit_len] += (tone * 0.4 + noise * 0.6) * 0.35
            # Hi-hat on 8th notes
            for sub in [0.0, 0.5]:
                hh_idx = int((t_beat + sub * beat_dur) * SAMPLE_RATE)
                hh_len = int(0.04 * SAMPLE_RATE)
                if hh_idx + hh_len <= total_len:
                    noise = (np.random.rand(hh_len) * 2 - 1)
                    t_hh = np.linspace(0, 0.04, hh_len, False)
                    output[hh_idx:hh_idx+hh_len] += noise * np.exp(-t_hh * 90.0) * 0.14
                    
        elif pattern_name == "rave":
            # 4-on-the-floor kick, offbeat open hat, clap on 2 & 4
            hit_len = int(0.12 * SAMPLE_RATE)
            if b_idx + hit_len <= total_len:
                t = np.linspace(0, 0.12, hit_len, False)
                sweep = 200.0 * np.exp(-t * 50.0) + 45.0
                output[b_idx:b_idx+hit_len] += np.sin(np.cumsum(2*np.pi*sweep/SAMPLE_RATE)) * np.exp(-t*22.0) * 0.48
            # Offbeat open hi-hat
            oh_idx = int((t_beat + 0.5 * beat_dur) * SAMPLE_RATE)
            oh_len = int(0.10 * SAMPLE_RATE)
            if oh_idx + oh_len <= total_len:
                noise = (np.random.rand(oh_len) * 2 - 1)
                t_oh = np.linspace(0, 0.10, oh_len, False)
                output[oh_idx:oh_idx+oh_len] += noise * np.exp(-t_oh * 35.0) * 0.20
            # Clap on 2 & 4
            if beat % 2 == 1:
                cl_len = int(0.12 * SAMPLE_RATE)
                if b_idx + cl_len <= total_len:
                    noise = (np.random.rand(cl_len) * 2 - 1)
                    t_cl = np.linspace(0, 0.12, cl_len, False)
                    output[b_idx:b_idx+cl_len] += noise * np.exp(-t_cl * 30.0) * 0.32
    return output

# -------------------------------------------------------------
# BGM Track Compositions
# -------------------------------------------------------------

def generate_bgm_main_menu(out_path):
    # Authentic Soothing SpongeBob Hawaiian Tropical Breeze (Zero annoying shrill leads!)
    bpm = 100
    total_duration = 16.0 * (60.0 / bpm) # 9.6s seamless loop
    beat = 60.0 / bpm
    
    # 1. Warm Hawaiian Island Ukulele Chords (Gentle nylon strums)
    ukelele_track = np.zeros(int(SAMPLE_RATE * total_duration), dtype=np.float32)
    chords = [
        ([53, 57, 60, 65]), # F
        ([53, 57, 60, 65]), # F
        ([50, 58, 62, 65]), # Bb
        ([50, 58, 62, 65]), # Bb
        ([48, 55, 58, 60]), # C7
        ([48, 55, 58, 60]), # C7
        ([53, 57, 60, 65]), # F
        ([53, 57, 60, 65]), # F
        ([53, 57, 60, 65]), # F
        ([50, 58, 62, 65]), # Bb
        ([48, 55, 58, 60]), # C7
        ([53, 57, 60, 65]), # F
        ([50, 58, 62, 65]), # Bb
        ([48, 55, 58, 60]), # C7
        ([53, 57, 60, 65]), # F
        ([53, 57, 60, 65])  # F
    ]
    for b, ch in enumerate(chords):
        c_audio = synth_ukulele_chord(ch, beat * 0.95, strum_speed=0.024)
        st = int(b * beat * SAMPLE_RATE)
        en = min(len(ukelele_track), st + len(c_audio))
        ukelele_track[st:en] += c_audio[:en-st]
        
    # 2. Gentle Wooden Marimba / Island Mallet Melody (Warm, relaxing, zero screech)
    marimba_notes = [
        (0.0 * beat, 0.7 * beat, 65),  # F4
        (0.8 * beat, 0.5 * beat, 69),  # A4
        (1.5 * beat, 0.8 * beat, 72),  # C5
        (2.5 * beat, 0.7 * beat, 70),  # Bb4
        (3.3 * beat, 0.5 * beat, 67),  # G4
        (4.0 * beat, 0.8 * beat, 69),  # A4
        (5.0 * beat, 0.5 * beat, 65),  # F4
        (5.8 * beat, 0.8 * beat, 64),  # E4
        (7.0 * beat, 1.2 * beat, 65),  # F4
        (9.0 * beat, 0.7 * beat, 69),  # A4
        (10.0 * beat, 0.5 * beat, 72), # C5
        (11.0 * beat, 0.8 * beat, 74), # D5
        (12.0 * beat, 0.7 * beat, 72), # C5
        (13.0 * beat, 0.5 * beat, 69), # A4
        (14.0 * beat, 1.4 * beat, 65)  # F4
    ]
    marimba_track = synth_marimba_lead(marimba_notes, total_duration)
    
    # 3. Soft Acoustic Upright Walking Bass
    bass_notes = [
        (0*beat, 0.45*beat, 29), (1*beat, 0.45*beat, 36),
        (2*beat, 0.45*beat, 34), (3*beat, 0.45*beat, 29),
        (4*beat, 0.45*beat, 36), (5*beat, 0.45*beat, 31),
        (6*beat, 0.45*beat, 29), (7*beat, 0.45*beat, 36),
        (8*beat, 0.45*beat, 29), (9*beat, 0.45*beat, 34),
        (10*beat, 0.45*beat, 36), (11*beat, 0.45*beat, 29),
        (12*beat, 0.45*beat, 34), (13*beat, 0.45*beat, 36),
        (14*beat, 0.45*beat, 29), (15*beat, 0.45*beat, 29)
    ]
    bass_track = synth_bassline(bass_notes, total_duration, "acoustic")
    
    # 4. Subtle Tropical Coconut Percussion
    perc_track = synth_percussion_track("tropical", total_duration, bpm)
    
    mix = ukelele_track * 0.65 + marimba_track * 0.55 + bass_track * 0.70 + perc_track * 0.38
    mix = apply_lowpass(mix, 2400.0)
    save_wav(out_path, mix, target_peak=0.38)

def generate_bgm_lobby(out_path):
    # Authentic Relaxing SpongeBob Hawaiian Tropical Stroll: 112 BPM (Warm marimba, cozy ukulele)
    bpm = 112
    beat = 60.0 / bpm
    total_duration = 16.0 * beat # 8.57s seamless loop
    
    # 1. Warm Hawaiian Ukulele Rhythmic Chords (C -> Am -> Dm -> G7 progression)
    ukelele_track = np.zeros(int(SAMPLE_RATE * total_duration), dtype=np.float32)
    chords = [
        [60, 64, 67, 72], [60, 64, 67, 72], # C
        [57, 60, 64, 69], [57, 60, 64, 69], # Am
        [57, 62, 65, 69], [57, 62, 65, 69], # Dm
        [55, 59, 62, 67], [55, 59, 62, 67], # G7
        [60, 64, 67, 72], [60, 64, 67, 72], # C
        [57, 60, 64, 69], [57, 60, 64, 69], # Am
        [57, 62, 65, 69], [57, 62, 65, 69], # Dm
        [60, 64, 67, 72], [60, 64, 67, 72]  # C (resolving)
    ]
    for b, ch in enumerate(chords):
        c_audio = synth_ukulele_chord(ch, beat * 0.92, strum_speed=0.022)
        st = int(b * beat * SAMPLE_RATE)
        en = min(len(ukelele_track), st + len(c_audio))
        ukelele_track[st:en] += c_audio[:en-st]
        
    # 2. Sweet Wooden Marimba Melody (Authentic SpongeBob tropical stroll, ZERO harsh sliding sines)
    marimba_notes = [
        (0.0 * beat, 0.6 * beat, 64),  # E4
        (0.7 * beat, 0.6 * beat, 67),  # G4
        (1.5 * beat, 0.8 * beat, 72),  # C5
        (2.5 * beat, 0.7 * beat, 69),  # A4
        (3.3 * beat, 0.5 * beat, 67),  # G4
        (4.0 * beat, 0.8 * beat, 65),  # F4
        (5.0 * beat, 0.5 * beat, 62),  # D4
        (5.8 * beat, 0.8 * beat, 65),  # F4
        (7.0 * beat, 1.2 * beat, 67),  # G4
        (9.0 * beat, 0.6 * beat, 64),  # E4
        (10.0 * beat, 0.6 * beat, 67), # G4
        (11.0 * beat, 0.8 * beat, 71), # B4
        (12.0 * beat, 0.7 * beat, 72), # C5
        (13.0 * beat, 0.5 * beat, 67), # G4
        (14.0 * beat, 1.4 * beat, 60)  # C4
    ]
    marimba_track = synth_marimba_lead(marimba_notes, total_duration)
    
    # 3. Warm Acoustic Upright Walking Bass
    bass_notes = [
        (0*beat, 0.45*beat, 36), (1*beat, 0.45*beat, 43),
        (2*beat, 0.45*beat, 33), (3*beat, 0.45*beat, 40),
        (4*beat, 0.45*beat, 38), (5*beat, 0.45*beat, 33),
        (6*beat, 0.45*beat, 31), (7*beat, 0.45*beat, 38),
        (8*beat, 0.45*beat, 36), (9*beat, 0.45*beat, 43),
        (10*beat, 0.45*beat, 33), (11*beat, 0.45*beat, 40),
        (12*beat, 0.45*beat, 38), (13*beat, 0.45*beat, 31),
        (14*beat, 0.80*beat, 36)
    ]
    bass_track = synth_bassline(bass_notes, total_duration, "acoustic")
    
    # 4. Soft Coconut & Wood Tap Percussion (gentle, warm tropical groove)
    perc_track = synth_percussion_track("tropical", total_duration, bpm)
    
    mix = ukelele_track * 0.65 + marimba_track * 0.55 + bass_track * 0.70 + perc_track * 0.38
    mix = apply_lowpass(mix, 2400.0)
    save_wav(out_path, mix, target_peak=0.38)

def generate_bgm_zone1_outskirts(out_path):
    # Surf rock battle theme ("Ripped Pants" surf guitar): 135 BPM
    bpm = 135
    beat = 60.0 / bpm
    total_duration = 16.0 * beat # 7.1s
    
    # Surf guitar twangy heroic melody
    surf_notes = [
        (0.0*beat, 0.4*beat, 64), (0.5*beat, 0.4*beat, 64),
        (1.0*beat, 0.4*beat, 67), (1.5*beat, 0.4*beat, 69),
        (2.0*beat, 0.9*beat, 71), (3.0*beat, 0.4*beat, 69),
        (3.5*beat, 0.4*beat, 67), (4.0*beat, 0.8*beat, 64),
        (5.0*beat, 0.4*beat, 62), (5.5*beat, 0.4*beat, 64),
        (6.0*beat, 0.8*beat, 67), (7.0*beat, 0.8*beat, 69),
        (8.0*beat, 0.4*beat, 71), (8.5*beat, 0.4*beat, 74),
        (9.0*beat, 0.8*beat, 76), (10.0*beat, 0.4*beat, 74),
        (10.5*beat, 0.4*beat, 71), (11.0*beat, 0.8*beat, 69),
        (12.0*beat, 0.4*beat, 67), (12.5*beat, 0.4*beat, 64),
        (13.0*beat, 0.4*beat, 67), (13.5*beat, 0.4*beat, 69),
        (14.0*beat, 1.6*beat, 64)
    ]
    surf_track = synth_surf_guitar_lead(surf_notes, total_duration)
    
    # Walking bass
    bass_notes = [
        (0*beat, 0.35*beat, 28), (1*beat, 0.35*beat, 31),
        (2*beat, 0.35*beat, 35), (3*beat, 0.35*beat, 33),
        (4*beat, 0.35*beat, 28), (5*beat, 0.35*beat, 31),
        (6*beat, 0.35*beat, 35), (7*beat, 0.35*beat, 38),
        (8*beat, 0.35*beat, 40), (9*beat, 0.35*beat, 38),
        (10*beat, 0.35*beat, 35), (11*beat, 0.35*beat, 33),
        (12*beat, 0.35*beat, 31), (13*beat, 0.35*beat, 33),
        (14*beat, 0.8*beat, 28)
    ]
    bass_track = synth_bassline(bass_notes, total_duration, "acoustic")
    perc_track = synth_percussion_track("surf_rock", total_duration, bpm)
    
    mix = surf_track * 1.1 + bass_track * 0.85 + perc_track * 0.85
    save_wav(out_path, mix)

def generate_bgm_zone2_krusty(out_path):
    # Fast ragtime kitchen rush: 155 BPM
    bpm = 155
    beat = 60.0 / bpm
    total_duration = 16.0 * beat # 6.2s
    
    rag_notes = [
        (0.0*beat, 0.2*beat, 60), (0.25*beat, 0.2*beat, 61),
        (0.5*beat, 0.4*beat, 62), (1.0*beat, 0.4*beat, 64),
        (1.5*beat, 0.4*beat, 65), (2.0*beat, 0.8*beat, 67),
        (3.0*beat, 0.4*beat, 69), (3.5*beat, 0.4*beat, 67),
        (4.0*beat, 0.4*beat, 65), (4.5*beat, 0.4*beat, 64),
        (5.0*beat, 0.8*beat, 62), (6.0*beat, 0.4*beat, 60),
        (6.5*beat, 0.4*beat, 62), (7.0*beat, 0.8*beat, 64),
        (8.0*beat, 0.2*beat, 60), (8.25*beat, 0.2*beat, 61),
        (8.5*beat, 0.4*beat, 62), (9.0*beat, 0.4*beat, 67),
        (9.5*beat, 0.4*beat, 72), (10.0*beat, 0.8*beat, 71),
        (11.0*beat, 0.4*beat, 69), (11.5*beat, 0.4*beat, 67),
        (12.0*beat, 0.4*beat, 65), (12.5*beat, 0.4*beat, 64),
        (13.0*beat, 0.4*beat, 62), (13.5*beat, 0.4*beat, 59),
        (14.0*beat, 1.5*beat, 60)
    ]
    lead_track = synth_accordion_lead(rag_notes, total_duration)
    
    bass_notes = [
        (0*beat, 0.3*beat, 36), (1*beat, 0.3*beat, 43),
        (2*beat, 0.3*beat, 36), (3*beat, 0.3*beat, 43),
        (4*beat, 0.3*beat, 38), (5*beat, 0.3*beat, 43),
        (6*beat, 0.3*beat, 36), (7*beat, 0.3*beat, 43),
        (8*beat, 0.3*beat, 36), (9*beat, 0.3*beat, 43),
        (10*beat, 0.3*beat, 33), (11*beat, 0.3*beat, 40),
        (12*beat, 0.3*beat, 41), (13*beat, 0.3*beat, 43),
        (14*beat, 0.8*beat, 36)
    ]
    bass_track = synth_bassline(bass_notes, total_duration, "tuba")
    perc_track = synth_percussion_track("polka", total_duration, bpm)
    
    mix = lead_track * 1.05 + bass_track * 0.9 + perc_track * 0.8
    save_wav(out_path, mix)

def generate_bgm_zone3_squidward(out_path):
    # Pretentious artistic clarinet concerto: 110 BPM
    bpm = 110
    beat = 60.0 / bpm
    total_duration = 16.0 * beat # 8.7s
    
    clar_notes = [
        (0.0*beat, 0.8*beat, 62), (1.0*beat, 0.8*beat, 65),
        (2.0*beat, 0.4*beat, 69), (2.5*beat, 0.4*beat, 70),
        (3.0*beat, 0.8*beat, 69), (4.0*beat, 0.4*beat, 65),
        (4.5*beat, 0.4*beat, 66), # Comic dissonant note!
        (5.0*beat, 0.8*beat, 67), (6.0*beat, 0.8*beat, 65),
        (7.0*beat, 0.8*beat, 62), (8.0*beat, 0.4*beat, 62),
        (8.5*beat, 0.4*beat, 65), (9.0*beat, 0.4*beat, 69),
        (9.5*beat, 0.4*beat, 74), (10.0*beat, 0.8*beat, 73),
        (11.0*beat, 0.4*beat, 70), (11.5*beat, 0.4*beat, 69),
        (12.0*beat, 0.8*beat, 65), (13.0*beat, 0.8*beat, 64),
        (14.0*beat, 1.8*beat, 62)
    ]
    clar_track = synth_clarinet_lead(clar_notes, total_duration)
    
    bass_notes = [
        (0*beat, 0.4*beat, 26), (1*beat, 0.4*beat, 33),
        (2*beat, 0.4*beat, 34), (3*beat, 0.4*beat, 33),
        (4*beat, 0.4*beat, 31), (5*beat, 0.4*beat, 35),
        (6*beat, 0.4*beat, 29), (7*beat, 0.4*beat, 33),
        (8*beat, 0.4*beat, 26), (9*beat, 0.4*beat, 33),
        (10*beat, 0.4*beat, 28), (11*beat, 0.4*beat, 34),
        (12*beat, 0.4*beat, 31), (13*beat, 0.4*beat, 33),
        (14*beat, 1.2*beat, 26)
    ]
    bass_track = synth_bassline(bass_notes, total_duration, "acoustic")
    perc_track = synth_percussion_track("tropical", total_duration, bpm)
    
    mix = clar_track * 1.15 + bass_track * 0.8 + perc_track * 0.5
    save_wav(out_path, mix)

def generate_bgm_infinity(out_path):
    # "Jellyfish Jam" underwater techno rave: 128 BPM
    bpm = 128
    beat = 60.0 / bpm
    total_duration = 16.0 * beat # 7.5s
    
    # Fast synth bass 16th note arpeggios
    bass_notes = []
    root = 42 # F#
    for b in range(16):
        t_sub = b * beat
        bass_notes.append((t_sub + 0.00*beat, 0.2*beat, root))
        bass_notes.append((t_sub + 0.25*beat, 0.2*beat, root))
        bass_notes.append((t_sub + 0.50*beat, 0.2*beat, root + 7 if b % 4 == 3 else root))
        bass_notes.append((t_sub + 0.75*beat, 0.2*beat, root + 5 if b % 2 == 1 else root))
    bass_track = synth_bassline(bass_notes, total_duration, "synth")
    
    # Jellyfish Jam hook synth lead
    lead_notes = [
        (0.0*beat, 0.4*beat, 66), (0.5*beat, 0.4*beat, 66),
        (1.0*beat, 0.4*beat, 69), (1.5*beat, 0.4*beat, 71),
        (2.0*beat, 0.8*beat, 73), (3.0*beat, 0.8*beat, 71),
        (4.0*beat, 0.4*beat, 69), (4.5*beat, 0.4*beat, 66),
        (5.0*beat, 0.4*beat, 64), (5.5*beat, 0.4*beat, 66),
        (6.0*beat, 1.2*beat, 69), (8.0*beat, 0.4*beat, 66),
        (8.5*beat, 0.4*beat, 69), (9.0*beat, 0.4*beat, 73),
        (9.5*beat, 0.4*beat, 76), (10.0*beat, 0.8*beat, 78),
        (11.0*beat, 0.8*beat, 76), (12.0*beat, 0.4*beat, 73),
        (12.5*beat, 0.4*beat, 71), (13.0*beat, 0.4*beat, 69),
        (13.5*beat, 0.4*beat, 71), (14.0*beat, 1.5*beat, 66)
    ]
    lead_track = synth_surf_guitar_lead(lead_notes, total_duration)
    perc_track = synth_percussion_track("rave", total_duration, bpm)
    
    mix = bass_track * 1.0 + lead_track * 0.95 + perc_track * 0.95
    save_wav(out_path, mix)

def generate_bgm_victory(out_path):
    # Celebratory triumphant fanfare: 3.8s
    duration = 3.8
    notes = [
        (0.0, 0.22, 60), (0.24, 0.22, 64), (0.48, 0.22, 67),
        (0.72, 0.65, 72), (1.45, 0.22, 69), (1.70, 0.22, 71),
        (1.95, 1.60, 72)
    ]
    brass = synth_accordion_lead(notes, duration)
    # Uplifting arpeggio backing
    arp = synth_ukulele_chord([60, 64, 67, 72, 76], 2.2, 0.04)
    total_len = int(SAMPLE_RATE * duration)
    track = np.zeros(total_len, dtype=np.float32)
    track[:len(brass)] += brass * 1.1
    arp_start = int(0.72 * SAMPLE_RATE)
    track[arp_start:arp_start+len(arp)] += arp * 0.7
    save_wav(out_path, track)

def generate_bgm_defeat(out_path):
    # Comedic sad trombone: "Wah - Wah - Wah - Waaahhhh" (3.2s)
    total_len = int(SAMPLE_RATE * 3.2)
    output = np.zeros(total_len, dtype=np.float32)
    
    # 4 notes: G3 -> F#3 -> F3 -> E3 (with descending slide)
    notes = [
        (0.0, 0.45, 55, 54),
        (0.55, 0.45, 54, 53),
        (1.10, 0.45, 53, 52),
        (1.65, 1.25, 52, 47) # Long sad downward slide
    ]
    for st, dur, m_from, m_to in notes:
        s_idx = int(st * SAMPLE_RATE)
        n_len = int(dur * SAMPLE_RATE)
        t = np.linspace(0, dur, n_len, False)
        f_from = note_freq(m_from)
        f_to = note_freq(m_to)
        freq = f_from + (f_to - f_from) * (t / dur)
        # Trombone brassy buzz with vibrato
        vib = 1.0 + 0.02 * np.sin(2 * np.pi * 5.0 * t)
        phase = np.cumsum(2 * np.pi * freq * vib / SAMPLE_RATE)
        wave = (
            0.85 * np.sin(phase) +
            0.55 * np.sin(phase * 2.0) +
            0.35 * np.sin(phase * 3.0) +
            0.20 * np.sin(phase * 4.0)
        )
        env = np.sin(np.pi * (t / dur) ** 0.6)
        output[s_idx:s_idx+n_len] += wave * env * 0.45
        
    # Comical sad bubble pop at the very end
    pop_idx = int(2.75 * SAMPLE_RATE)
    pop_len = int(0.08 * SAMPLE_RATE)
    t_pop = np.linspace(0, 0.08, pop_len, False)
    pop_freq = 600.0 * np.exp(-t_pop * 45.0) + 120.0
    output[pop_idx:pop_idx+pop_len] += np.sin(np.cumsum(2*np.pi*pop_freq/SAMPLE_RATE)) * np.exp(-t_pop * 50.0) * 0.35
    save_wav(out_path, output)

# -------------------------------------------------------------
# Complete SFX Synthesizers
# -------------------------------------------------------------

def generate_sfx(sfx_dir):
    # 1. SpongeBob Audible Cartoon Rubber Boot Squeak (0.10s - punchy, iconic, audible)
    dur = 0.10
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Vibrant cartoon rubber squeak: sweeps 680 Hz -> 920 Hz -> 720 Hz
    f_squeak = 680.0 + 240.0 * np.sin(np.pi * (t / dur) ** 0.75)
    phase = np.cumsum(2 * np.pi * f_squeak / SAMPLE_RATE)
    # Suction envelope + second harmonic for cartoon presence
    squeak = (
        np.sin(phase) +
        0.30 * np.sin(phase * 2.0)
    ) * (np.sin(np.pi * t / dur) ** 1.1)
    # Punchy rubber heel tap (160 Hz)
    tap = np.sin(2 * np.pi * 160.0 * t) * np.exp(-t * 50.0) * 0.45
    combined = squeak * 0.75 + tap * 0.35
    save_wav(os.path.join(sfx_dir, "sfx_footstep_squeak.wav"), combined, target_peak=0.36)

    # 2. Jump Cartoon Spring Boing (0.25s)
    dur = 0.25
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_spring = 150.0 + 260.0 * (t / dur) ** 0.5 + 25.0 * np.sin(2 * np.pi * 18.0 * t)
    boing = np.sin(np.cumsum(2 * np.pi * f_spring / SAMPLE_RATE)) * np.exp(-t * 9.5)
    save_wav(os.path.join(sfx_dir, "sfx_jump.wav"), boing, target_peak=0.35)

    # 3. Teleport Soft Bubble Hop (0.35s - 4 ascending bubbles + gentle chime, ZERO white noise)
    dur = 0.35
    n = int(SAMPLE_RATE * dur)
    teleport = np.zeros(n, dtype=np.float32)
    # Ascending water bubble pop frequencies: 340, 460, 580, 720 Hz
    bubble_pitches = [340.0, 460.0, 580.0, 720.0]
    for bi, bp in enumerate(bubble_pitches):
        b_st = int(bi * 0.065 * SAMPLE_RATE)
        b_rem = n - b_st
        if b_rem <= 0:
            continue
        t_b = np.linspace(0, b_rem / SAMPLE_RATE, b_rem, False)
        # Pitch drops quickly like a real soap bubble popping
        f_pop = bp * np.exp(-t_b * 32.0) + bp * 0.4
        pop_w = np.sin(np.cumsum(2 * np.pi * f_pop / SAMPLE_RATE)) * np.exp(-t_b * 28.0)
        teleport[b_st:] += pop_w * 0.40
    # Soft warm vibraphone chime triad (F4, A4, C5)
    t_full = np.linspace(0, dur, n, False)
    chime_triad = (
        np.sin(2 * np.pi * 349.2 * t_full) * 0.45 +
        np.sin(2 * np.pi * 440.0 * t_full) * 0.35 +
        np.sin(2 * np.pi * 523.3 * t_full) * 0.25
    ) * np.exp(-t_full * 7.5) * np.sin(np.pi * np.clip(t_full / 0.06, 0.0, 1.0))
    teleport += chime_triad * 0.30
    save_wav(os.path.join(sfx_dir, "sfx_teleport.wav"), teleport, target_peak=0.38)

    # 4. Tower Placement Splash Thud (0.22s)
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    thud = np.sin(2 * np.pi * 85.0 * np.exp(-t * 15.0) * t) * np.exp(-t * 18.0)
    splash = (np.random.rand(n) * 2 - 1) * np.exp(-t * 22.0)
    save_wav(os.path.join(sfx_dir, "sfx_tower_place.wav"), thud * 0.7 + splash * 0.35)

    # 5. Tower Upgrade Chime (0.42s)
    dur = 0.42
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    chime = np.zeros(n, dtype=np.float32)
    for i, m in enumerate([60, 64, 67, 72]):
        st = int(i * 0.08 * SAMPLE_RATE)
        rem = n - st
        t_rem = np.linspace(0, rem / SAMPLE_RATE, rem, False)
        f = note_freq(m)
        chime[st:] += (np.sin(2 * np.pi * f * t_rem) + 0.3 * np.sin(2 * np.pi * 2 * f * t_rem)) * np.exp(-t_rem * 12.0) * 0.25
    save_wav(os.path.join(sfx_dir, "sfx_tower_upgrade.wav"), chime)

    # 6. Tower Sell Cash Register (0.35s)
    dur = 0.35
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    # Bell ting + drawer clunk
    bell = (np.sin(2 * np.pi * 1850.0 * t) + 0.5 * np.sin(2 * np.pi * 3700.0 * t)) * np.exp(-t * 14.0)
    clunk = np.sin(2 * np.pi * 120.0 * t) * np.exp(-t * 25.0)
    coins = (np.random.rand(n) * 2 - 1) * np.exp(-t * 18.0) * 0.3
    save_wav(os.path.join(sfx_dir, "sfx_tower_sell.wav"), bell * 0.6 + clunk * 0.3 + coins * 0.3)

    # 7. Bubble Shoot (0.14s)
    dur = 0.14
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_b = 350.0 + 850.0 * (t / dur) ** 2.0
    bubble_shoot = np.sin(np.cumsum(2 * np.pi * f_b / SAMPLE_RATE)) * np.exp(-t * 16.0)
    save_wav(os.path.join(sfx_dir, "sfx_bubble_shoot.wav"), bubble_shoot)

    # 8. Bubble Pop (0.07s)
    dur = 0.07
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_pop = 950.0 * np.exp(-t * 55.0) + 160.0
    pop = np.sin(np.cumsum(2 * np.pi * f_pop / SAMPLE_RATE)) * np.exp(-t * 45.0)
    save_wav(os.path.join(sfx_dir, "sfx_bubble_pop.wav"), pop)

    # 9. Boulder Throw Whoosh (0.24s)
    dur = 0.24
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_whoosh = 220.0 * np.exp(-t * 8.0) + 60.0
    whoosh = np.sin(np.cumsum(2 * np.pi * f_whoosh / SAMPLE_RATE)) * np.sin(np.pi * t / dur)
    noise = (np.random.rand(n) * 2 - 1) * np.sin(np.pi * t / dur) * 0.25
    save_wav(os.path.join(sfx_dir, "sfx_boulder_throw.wav"), whoosh * 0.7 + noise)

    # 10. Boulder Impact Slam (0.32s)
    dur = 0.32
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    slam = np.sin(2 * np.pi * 55.0 * t) * np.exp(-t * 12.0)
    gravel = (np.random.rand(n) * 2 - 1) * np.exp(-t * 20.0) * 0.4
    save_wav(os.path.join(sfx_dir, "sfx_boulder_impact.wav"), slam * 0.7 + gravel * 0.4)

    # 11. Clarinet Blast / Honk (0.28s)
    dur = 0.28
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_clar = 580.0 + 30.0 * np.sin(2 * np.pi * 12.0 * t)
    c_blast = np.sign(np.sin(2 * np.pi * f_clar * t)) * np.exp(-t * 7.0)
    save_wav(os.path.join(sfx_dir, "sfx_clarinet_blast.wav"), c_blast * 0.6)

    # 12. Spatula Whack / Slap (0.18s)
    dur = 0.18
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    ping1 = np.sin(2 * np.pi * 1250.0 * t) * np.exp(-t * 24.0)
    ping2 = np.sin(2 * np.pi * 2600.0 * t) * np.exp(-t * 32.0)
    slap = (np.random.rand(n) * 2 - 1) * np.exp(-t * 40.0) * 0.5
    save_wav(os.path.join(sfx_dir, "sfx_spatula_hit.wav"), ping1 * 0.4 + ping2 * 0.3 + slap * 0.3)

    # 13. Karate Chop (0.20s)
    dur = 0.20
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    whoosh = (np.random.rand(n) * 2 - 1) * np.sin(np.pi * t / dur) * 0.4
    snap = np.sin(2 * np.pi * 320.0 * t) * np.exp(-t * 30.0) * 0.6
    save_wav(os.path.join(sfx_dir, "sfx_karate_chop.wav"), whoosh + snap)

    # 14. Mr. Krabs Money Fountain (0.55s)
    dur = 0.55
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    fountain = np.zeros(n, dtype=np.float32)
    for c_i in range(8):
        c_st = int(c_i * 0.055 * SAMPLE_RATE)
        c_rem = n - c_st
        if c_rem <= 0:
            continue
        c_t = np.linspace(0, c_rem / SAMPLE_RATE, c_rem, False)
        f_coin = 2200.0 + c_i * 180.0
        fountain[c_st:] += np.sin(2 * np.pi * f_coin * c_t) * np.exp(-c_t * 25.0) * 0.22
    save_wav(os.path.join(sfx_dir, "sfx_money_fountain.wav"), fountain)

    # 15. Gary's Meow (0.45s)
    dur = 0.45
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_meow = 420.0 + 160.0 * np.sin(np.pi * (t / dur) ** 0.8)
    meow = np.sin(np.cumsum(2 * np.pi * f_meow / SAMPLE_RATE)) * np.sin(np.pi * t / dur) ** 0.5
    save_wav(os.path.join(sfx_dir, "sfx_meow.wav"), meow * 0.65)

    # 16. Plankton Laser Zap (0.16s)
    dur = 0.16
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_laser = 2600.0 * np.exp(-t * 25.0) + 200.0
    laser = np.sin(np.cumsum(2 * np.pi * f_laser / SAMPLE_RATE)) * np.exp(-t * 14.0)
    save_wav(os.path.join(sfx_dir, "sfx_plankton_laser.wav"), laser * 0.7)

    # 17. Enemy Spawn Portal Warble (0.40s)
    dur = 0.40
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_warble = 110.0 + 35.0 * np.sin(2 * np.pi * 14.0 * t)
    warble = np.sin(np.cumsum(2 * np.pi * f_warble / SAMPLE_RATE)) * np.sin(np.pi * t / dur)
    save_wav(os.path.join(sfx_dir, "sfx_enemy_spawn.wav"), warble * 0.6)

    # 18. Enemy Hit Squish (0.12s)
    dur = 0.12
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_hit = 280.0 * np.exp(-t * 30.0) + 90.0
    hit = np.sin(np.cumsum(2 * np.pi * f_hit / SAMPLE_RATE)) * np.exp(-t * 22.0)
    save_wav(os.path.join(sfx_dir, "sfx_enemy_hit.wav"), hit * 0.65)

    # 19. Enemy Death Splat Pop (0.22s)
    dur = 0.22
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_splat = 650.0 * np.exp(-t * 35.0) + 80.0
    splat = np.sin(np.cumsum(2 * np.pi * f_splat / SAMPLE_RATE)) * np.exp(-t * 18.0)
    noise = (np.random.rand(n) * 2 - 1) * np.exp(-t * 22.0) * 0.35
    save_wav(os.path.join(sfx_dir, "sfx_enemy_death.wav"), splat * 0.65 + noise)

    # 20. Boss Alert Foghorn (1.1s)
    dur = 1.10
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    horn1 = np.sin(2 * np.pi * 68.0 * t)
    horn2 = np.sin(2 * np.pi * 136.0 * t) * 0.6
    horn3 = np.sin(2 * np.pi * 204.0 * t) * 0.35
    env_horn = np.sin(np.pi * (t / dur) ** 0.4)
    foghorn = (horn1 + horn2 + horn3) * env_horn * 0.75
    save_wav(os.path.join(sfx_dir, "sfx_boss_alert.wav"), foghorn)

    # 21. Base Damage Warning (0.35s)
    dur = 0.35
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    alarm = np.sin(2 * np.pi * (440.0 + 80.0 * np.sin(2 * np.pi * 8.0 * t)) * t) * np.exp(-t * 7.0)
    crack = (np.random.rand(n) * 2 - 1) * np.exp(-t * 28.0) * 0.4
    save_wav(os.path.join(sfx_dir, "sfx_base_damage.wav"), alarm * 0.6 + crack * 0.4)

    # 22. UI Bubble Button Click (0.04s - subtle gentle bubble tap)
    dur = 0.04
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    f_click = 480.0 + 160.0 * (t / dur)
    click = np.sin(np.cumsum(2 * np.pi * f_click / SAMPLE_RATE)) * np.sin(np.pi * t / dur)
    save_wav(os.path.join(sfx_dir, "sfx_ui_click.wav"), click, target_peak=0.30)

    # 23. UI Modal Open Warm Chime (0.16s - 2-note marimba/bubble chime, ZERO white noise)
    dur = 0.16
    n = int(SAMPLE_RATE * dur)
    ui_open = np.zeros(n, dtype=np.float32)
    for i, m in enumerate([72, 79]): # C5 -> G5
        st = int(i * 0.05 * SAMPLE_RATE)
        rem = n - st
        t_m = np.linspace(0, rem / SAMPLE_RATE, rem, False)
        f_m = note_freq(m)
        ui_open[st:] += (np.sin(2 * np.pi * f_m * t_m) + 0.25 * np.sin(2 * np.pi * 2 * f_m * t_m)) * np.exp(-t_m * 22.0) * 0.40
    save_wav(os.path.join(sfx_dir, "sfx_ui_open.wav"), ui_open, target_peak=0.35)

    # 24. UI Modal Close Gentle Tap (0.10s - descending wooden tap, ZERO white noise)
    dur = 0.10
    n = int(SAMPLE_RATE * dur)
    ui_close = np.zeros(n, dtype=np.float32)
    for i, m in enumerate([79, 72]): # G5 -> C5
        st = int(i * 0.04 * SAMPLE_RATE)
        rem = n - st
        t_m = np.linspace(0, rem / SAMPLE_RATE, rem, False)
        f_m = note_freq(m)
        ui_close[st:] += (np.sin(2 * np.pi * f_m * t_m) + 0.2 * np.sin(2 * np.pi * 2 * f_m * t_m)) * np.exp(-t_m * 28.0) * 0.35
    save_wav(os.path.join(sfx_dir, "sfx_ui_close.wav"), ui_close, target_peak=0.30)

    # 25. Coins Pickup (0.20s)
    dur = 0.20
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    coin1 = np.sin(2 * np.pi * 1950.0 * t) * np.exp(-t * 22.0)
    coin2 = np.sin(2 * np.pi * 2600.0 * t) * np.exp(-t * 28.0)
    save_wav(os.path.join(sfx_dir, "sfx_coins.wav"), coin1 * 0.5 + coin2 * 0.4, target_peak=0.45)

    # 26. Gems Shimmer (0.35s)
    dur = 0.35
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    gem = (np.sin(2 * np.pi * 2800.0 * t) + 0.6 * np.sin(2 * np.pi * 3500.0 * t) + 0.4 * np.sin(2 * np.pi * 4200.0 * t)) * np.exp(-t * 12.0)
    save_wav(os.path.join(sfx_dir, "sfx_gems.wav"), gem * 0.5, target_peak=0.42)

    # 27. Summon Pull Fanfare (0.60s)
    dur = 0.60
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    summon = np.zeros(n, dtype=np.float32)
    for i, m in enumerate([55, 60, 64, 67, 72, 79]):
        st = int(i * 0.08 * SAMPLE_RATE)
        rem = n - st
        t_rem = np.linspace(0, rem / SAMPLE_RATE, rem, False)
        f = note_freq(m)
        summon[st:] += np.sin(2 * np.pi * f * t_rem) * np.exp(-t_rem * 10.0) * 0.22
    save_wav(os.path.join(sfx_dir, "sfx_summon_pull.wav"), summon, target_peak=0.55)

    # 28. Trait Reroll Roulette (0.42s)
    dur = 0.42
    n = int(SAMPLE_RATE * dur)
    t = np.linspace(0, dur, n, False)
    clicks = np.zeros(n, dtype=np.float32)
    for k in range(12):
        pos = int((k / 12.0) ** 1.5 * n * 0.8)
        if pos < n - 500:
            clicks[pos:pos+500] += np.sin(2 * np.pi * 650.0 * np.linspace(0, 500/SAMPLE_RATE, 500)) * 0.35
    zap = np.sin(2 * np.pi * (450 + 250 * t) * t) * np.exp(-t * 8.0) * 0.30
    save_wav(os.path.join(sfx_dir, "sfx_trait_reroll.wav"), clicks + zap, target_peak=0.40)

    # 29. Stage Enter / Transition (0.85s - Authentic SpongeBob Undersea Bubble Cascade & Harp Glissando, ZERO white noise)
    dur = 0.85
    n = int(SAMPLE_RATE * dur)
    trans_audio = np.zeros(n, dtype=np.float32)
    # 8 rising water bubbles
    bubble_seq = [260, 320, 390, 470, 540, 620, 710, 800]
    for bi, bp in enumerate(bubble_seq):
        b_st = int(bi * 0.085 * SAMPLE_RATE)
        b_rem = n - b_st
        if b_rem <= 0:
            continue
        t_b = np.linspace(0, b_rem / SAMPLE_RATE, b_rem, False)
        f_b = bp * np.exp(-t_b * 30.0) + bp * 0.35
        b_wave = np.sin(np.cumsum(2 * np.pi * f_b / SAMPLE_RATE)) * np.exp(-t_b * 22.0)
        trans_audio[b_st:] += b_wave * 0.35
    # Dreamy Hawaiian harp arpeggio (C4, E4, G4, B4, C5, E5)
    harp_notes = [60, 64, 67, 71, 72, 76]
    for hi, hm in enumerate(harp_notes):
        h_st = int((0.15 + hi * 0.09) * SAMPLE_RATE)
        h_rem = n - h_st
        if h_rem <= 0:
            continue
        t_h = np.linspace(0, h_rem / SAMPLE_RATE, h_rem, False)
        f_h = note_freq(hm)
        h_wave = (np.sin(2 * np.pi * f_h * t_h) + 0.3 * np.sin(2 * np.pi * 2 * f_h * t_h)) * np.exp(-t_h * 8.0)
        trans_audio[h_st:] += h_wave * 0.28
    save_wav(os.path.join(sfx_dir, "sfx_stage_enter.wav"), trans_audio, target_peak=0.45)

if __name__ == "__main__":
    base_dir = r"D:\Godot\Projects\SpongeBob_Tower_Defense\assets\audio"
    bgm_dir = os.path.join(base_dir, "bgm")
    sfx_dir = os.path.join(base_dir, "sfx")
    
    print("=== Generating SpongeBob Themed BGM Tracks ===")
    generate_bgm_main_menu(os.path.join(bgm_dir, "bgm_main_menu.wav"))
    generate_bgm_lobby(os.path.join(bgm_dir, "bgm_lobby.wav"))
    generate_bgm_zone1_outskirts(os.path.join(bgm_dir, "bgm_zone1_outskirts.wav"))
    generate_bgm_zone2_krusty(os.path.join(bgm_dir, "bgm_zone2_krusty.wav"))
    generate_bgm_zone3_squidward(os.path.join(bgm_dir, "bgm_zone3_squidward.wav"))
    generate_bgm_infinity(os.path.join(bgm_dir, "bgm_infinity.wav"))
    generate_bgm_victory(os.path.join(bgm_dir, "bgm_victory.wav"))
    generate_bgm_defeat(os.path.join(bgm_dir, "bgm_defeat.wav"))
    
    print("\n=== Generating Complete SpongeBob SFX Library ===")
    generate_sfx(sfx_dir)
    print("\n=== Audio Generation Complete 100%! ===")
