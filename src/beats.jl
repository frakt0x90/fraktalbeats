using MusicManipulations


const quarter = 960 # MIDI duration per quarter note

position(note) = note.position
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

#TODO: I think this can be simplified to just use notes instead of vectors of Notes{Note} for each level.
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

#Note is pitch vel, pos, dur
startnotes = Notes([Note(67, 100, 0, 2*quarter), Note(74, 100, 2*quarter, quarter), Note(71, 100, 3*quarter, quarter)])
#startnotes = Notes([Note(42, 100, 0, 2*quarter), Note(42, 100, 2*quarter, quarter/3), Note(42, 100, 2*quarter + quarter/3, quarter/3), Note(42, 100, 2*quarter + 2*quarter/3, quarter/3), Note(42, 100, 3*quarter, quarter)])
iterations = 2
fractal = IFS(startnotes, iterations)
makeMIDIfile(fractal, "examples/ifs2.mid")
