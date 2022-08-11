using MusicManipulations


const quarter = 960 # duration per quarter note

position(note) = note.position
shift!(note, field, amount) = setfield!(note, Symbol(field), getfield(note, Symbol(field)) + round(UInt, amount))
scale!(note, field, amount) = setfield!(note, Symbol(field), round(UInt, getfield(note, Symbol(field)) * amount))
MusicManipulations.Notes(x::Vector{Notes{Note}}) = MusicManipulations.Notes(collect(Iterators.flatten(x)))

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

function IFS(notes, iterations, levels=[])
    push!(levels, notes)
    if iterations == 0
        return levels
    end
    level = Vector{Notes{Note}}()  # TODO: speed up by calcualting length and assigning.
    for note in notes
        newnotes = copy(notes)
        contract!(newnotes, note)
        push!(level, newnotes)
    end
    iterations -= 1
    return IFS(Notes(level), iterations, levels)
end


startnotes = Notes([Note(42, 100, 0, 2*quarter), Note(42, 100, 2*quarter, quarter), Note(42, 100, 3*quarter, quarter)])
fractal = IFS(startnotes, 1)