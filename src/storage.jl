abstract type ForwardMapStorage end

Base.length(storage::ForwardMapStorage) = length(getinputs(storage))
Base.lastindex(storage::ForwardMapStorage) = lastindex(getinputs(storage))
Base.firstindex(storage::ForwardMapStorage) = firstindex(getinputs(storage))

struct SimpleForwardMapStorage <: ForwardMapStorage
    inputs::Vector
    outputs::Vector
end

SimpleForwardMapStorage() = SimpleForwardMapStorage([], [])

function Base.getindex(storage::SimpleForwardMapStorage, i)
    return (storage.inputs[i], storage.outputs[i])
end

getinputs(storage::SimpleForwardMapStorage) = storage.inputs
getinputs(storage::SimpleForwardMapStorage, i) = storage.inputs[i]

getoutputs(storage::SimpleForwardMapStorage) = storage.outputs
getoutputs(storage::SimpleForwardMapStorage, i) = storage.outputs[i]

function store!(storage::SimpleForwardMapStorage, x, y)
    push!(storage.inputs, x)
    push!(storage.outputs, y)
end