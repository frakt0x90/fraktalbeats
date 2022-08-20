using MusicManipulations
using Base.Iterators


const quarter = 960 # MIDI duration per quarter note
const major_pat = [2, 2, 1, 2, 2, 2, 1]
const minor_pat = [2, 1, 2, 2, 1, 2, 2]
const harm_minor_pat = [2, 1, 2, 2, 1, 3, 1]
const rootnotes = (c=0, c♯=1, d♭=1, d=2, d♯=3, e♭=3, e=4, f=5, f♯=6, g♭=6, g=7, g♯=8, a♭=8, a=9, a♯=10, b♭=10, b=11)
const midi_maxpitch = 127

struct Scale
    pattern::Vector{Int}
    iterator::Iterators.Cycle{Vector{Int}}
    root::Symbol
end

Scale(pattern, root) = Scale(pattern, cycle(pattern), root)

function mode(index::Int, scale::Scale)
    newpattern = circshift(scale.pattern, -index + 1)
    Scale(newpattern, scale.root + index - 1)
end

function lock!(notes::Notes{Note}, scale::Scale)
    scalenotes = generate_notes(scale)
    for note in notes
        closestnote = argmin(abs.(note.pitch .- scalenotes))
        note.pitch = scalenotes[closestnote]
    end
end

function generate_notes(scale::Scale)
    startnote = rootnotes[scale.root]
    notes = [startnote]
    for step in scale.iterator
        startnote += step
        if startnote > midi_maxpitch
            return notes
        end
        push!(notes, startnote)
    end
end

scale!(note, field, amount) = setfield!(note, Symbol(field), round(UInt, getfield(note, Symbol(field)) * amount))
MusicManipulations.Notes(x::Vector{Notes{Note}}) = MusicManipulations.Notes(collect(Iterators.flatten(x)))

function shift!(note, field, amount)
    properfield = getfield(note, Symbol(field))
    setfield!(note, Symbol(field), properfield + round(typeof(properfield), amount))
end

function contract!(items, into)
    intoend = into.position + into.duration
    itemsbegin = minimum([note.position for note in items])
    items_end = maximum([note.position + note.duration for note in items])
    itemsduration = items_end - itemsbegin
    intoduration = intoend - into.position
    scalefactor = intoduration/itemsduration
    scale!.(items, :duration, scalefactor)
    scale!.(items, :position, scalefactor)
    shift!.(items, :position, into.position - itemsbegin)
end

function pitchcontract(notes::Notes{Note})
    newpitches = Vector{Int}()
    tonediffs = pitches(notes) .- convert(Int64, notes[1].pitch)
    for note in notes
        for tonediff in tonediffs
            newpitch = note.pitch + tonediff
            push!(newpitches, newpitch)
        end
    end
    return newpitches
end

#TODO: Maybe can be simplified to just use notes instead of vectors of Notes{Note} for each level.
function IFS(notes, iterations, levels=Vector{Notes{Note}}())
    push!(levels, notes)
    if iterations == 0
        return levels
    end
    level = Vector{Notes{Note}}()
    for note in notes
        newnotes = copy(notes)
        contract!(newnotes, note)
        push!(level, newnotes)
    end
    level = Notes(level)
    melody = pitchcontract(notes)
    for (notei, note) in enumerate(level)
        level.notes[notei].pitch = melody[notei]
    end
    iterations -= 1
    return IFS(level, iterations, levels)
end

function makeMIDIfile(fractal, location)
    file = MIDIFile()
    for (level, notes) in enumerate(fractal)
        track = MIDITrack()
        addnotes!(track, notes)
        addtrackname!(track, "level$level")
        push!(file.tracks, track)
    end
    writeMIDIFile(location, file)
end


#Note(pitch vel, pos, dur)
melodystart = Notes([Note(69, 100, 0, 2*quarter), Note(76, 100, 2*quarter, quarter), Note(72, 100, 3*quarter, quarter)])
drumstart = Notes([Note(42, 100, 0, quarter), Note(42, 100, quarter, quarter + quarter/2), Note(42, 100, 2*quarter + quarter/2, quarter/2), Note(42, 100, 3*quarter, quarter)])
iterations = 2
melodyscale = Scale(minor_pat, :a)
melody = IFS(melodystart, iterations)
lock!.(melody, Ref(melodyscale))
drums = IFS(drumstart, iterations)
makeMIDIfile(melody, "examples/ifsmelody.mid")
makeMIDIfile(drums, "examples/ifsdrums.mid")
