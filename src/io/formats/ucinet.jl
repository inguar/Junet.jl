# http://www.analytictech.com/networks/dataentry.htm
# http://www.analytictech.com/ucinet/help/hs5000.htm

function read_dl(io::IO)
    g = Graph(16)
    readline(io)
    readline(io)
    readline(io)
    readline(io)
    readline(io)
    readline(io)
    while !eof(io)
        l = readline(io)
        a, b, c = split(l, ' ')
        addedge!(g, parse(Int, a), parse(Int, b))
    end
    return g
end