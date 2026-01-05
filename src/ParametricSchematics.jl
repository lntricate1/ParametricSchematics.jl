module ParametricSchematics

using MinecraftDataStructures
using PooledArrays

struct Piece{T, x, y, z, X, Y, Z}
  data::AbstractArray{T, 3}
  start_x::NTuple{x, Int}
  start_y::NTuple{y, Int}
  start_z::NTuple{z, Int}
  tile_x::NTuple{X, Int}
  tile_y::NTuple{Y, Int}
  tile_z::NTuple{Z, Int}
end

struct MetaPiece{T, X, Y, Z}
  data::Array{<:AbstractArray{T, 3}, 3}
  blocksize_x::NTuple{X, Int}
  blocksize_y::NTuple{Y, Int}
  blocksize_z::NTuple{Z, Int}
  start_x::NTuple{X, Tuple{Int, Vararg{Int}}}
  start_y::NTuple{Y, Tuple{Int, Vararg{Int}}}
  start_z::NTuple{Z, Tuple{Int, Vararg{Int}}}
  stop_x::NTuple{X, Tuple{Int, Vararg{Int}}}
  stop_y::NTuple{Y, Tuple{Int, Vararg{Int}}}
  stop_z::NTuple{Z, Tuple{Int, Vararg{Int}}}
end

function tile(metapiece::MetaPiece{T, X, Y, Z}, start_indices::NTuple{3, Int},
  tile_count_x::NTuple{X, Int}, tile_count_y::NTuple{Y, Int},
  tile_count_z::NTuple{Z, Int}) where {T, X, Y, Z}
  width_x = total_width(metapiece.blocksize_x, start_indices[1], tile_count_x, metapiece.start_x, metapiece.stop_x)
  width_y = total_width(metapiece.blocksize_y, start_indices[2], tile_count_y, metapiece.start_y, metapiece.stop_y)
  width_z = total_width(metapiece.blocksize_z, start_indices[3], tile_count_z, metapiece.start_z, metapiece.stop_z)
  println("total width: ", (width_x, width_y, width_z))

  output = zeros(T, width_x, width_y, width_z)
  # start_index_x = metapiece.start_x[start_indices[1]]
  start_index_x = start_indices[1]
  # start_index_x = start[1]
  out_pos_x = 1
  for x in 1:X
    start_pos_x = metapiece.start_x[x][start_index_x]
    # start_index_y = start[2]
    start_index_y = start_indices[2]
    # start_index_y = metapiece.start_y[start_indices[2]]
    out_pos_y = 1
    for y in 1:Y
      start_pos_y = metapiece.start_y[y][start_index_y]
      # start_index_z = start[3]
      start_index_z = start_indices[3]
      # start_index_z = metapiece.start_z[start_indices[3]]
      out_pos_z = 1
      for z in 1:Z
        start_pos_z = metapiece.start_z[z][start_index_z]
        println("z=", z, ", start_pos_z=", start_pos_z)
        tile!(output, metapiece.data[x,y,z],
          (tile_count_x[x], tile_count_y[y], tile_count_z[z]),
          (start_pos_x, start_pos_y, start_pos_z),
          (out_pos_x, out_pos_y, out_pos_z),
          metapiece.stop_x[x], metapiece.stop_y[y], metapiece.stop_z[z])
        println("out_pos_z += ", total_width(metapiece.blocksize_z[z], start_pos_z, tile_count_z[z], metapiece.stop_z[z]))
        out_pos_z += total_width(metapiece.blocksize_z[z], start_pos_z, tile_count_z[z], metapiece.stop_z[z])
        stop_index_z = count(<(start_pos_z), metapiece.stop_z[z]) + tile_count_z[z]
        start_index_z = mod(stop_index_z - 1, length(metapiece.stop_z[z])) + 1
      end
      out_pos_y += total_width(metapiece.blocksize_y[y], start_pos_y, tile_count_y[y], metapiece.stop_y[y])
      stop_index_y = count(<(start_pos_y), metapiece.stop_y[y]) + tile_count_y[y]
      start_index_y = mod(stop_index_y - 1, length(metapiece.stop_y[y])) + 1
    end
    out_pos_x += total_width(metapiece.blocksize_x[x], start_pos_x, tile_count_x[x], metapiece.stop_x[x])
    stop_index_x = count(<(start_pos_x), metapiece.stop_x[x]) + tile_count_x[x]
    start_index_x = mod(stop_index_x - 1, length(metapiece.stop_x[x])) + 1
  end
  return output
end

function total_width(blocksize::NTuple{N, Int}, start_index::Int, tile_count::NTuple{N, Int}, start_pts::NTuple{N, Tuple{Int, Vararg{Int}}}, stop_pts::NTuple{N, Tuple{Int, Vararg{Int}}}) where N
  width = 0
  for i in 1:N
    start_pos = start_pts[i][start_index]
    println("i=", i, ", start_pos=", start_pos)
    width += total_width(blocksize[i], start_pos, tile_count[i], stop_pts[i])
    println("total_width=", total_width(blocksize[i], start_pos, tile_count[i], stop_pts[i]))
    stop_index = count(<(start_pos), stop_pts[i]) + tile_count[i]
    start_index = mod(stop_index - 1, length(stop_pts[i])) + 1
  end
  return width
end

function tile!(output::AbstractArray{T, 3}, piece::Piece{T, x, y, z, X, Y, Z},
  tile_count::NTuple{3, Int}, start_in::NTuple{3, Int},
  start_out::NTuple{3, Int}) where {T, x, y, z, X, Y, Z}
  tile!(output, piece.data, tile_count, start_in, start_out, piece.tile_x, piece.tile_y, piece.tile_z)
end

function tile!(output::AbstractArray{T, 3},
  block::AbstractArray{T, 3},
  tile_count::NTuple{3, Int},
  start_in::NTuple{3, Int},
  start_out::NTuple{3, Int},
  tile_x::NTuple{N1, Int},
  tile_y::NTuple{N2, Int},
  tile_z::NTuple{N3, Int}) where {T, N1, N2, N3}
  X, Y, Z = total_width.(size(block), start_in, tile_count, (tile_x, tile_y, tile_z))
  println("tiling with width ", (X, Y, Z), " from start_out ", start_out)
  for z in 1:Z
    for y in 1:Y
      for x in 1:X
        ox, oy, oz = (x, y, z) .+ start_out .- 1
        ix, iy, iz = mod.((x, y, z) .+ start_in .- 2, size(block)) .+ 1
        output[ox, oy, oz] = block[ix, iy, iz]
      end
    end
  end
  return output
end

function total_width(blocksize, start, tile_count, tile::NTuple{N, Int}) where N
  d, r = divrem(tile_count - 1, N)
  ending_pts_after_X = r+1
  ending_pts_before_X = count(<(start), tile)
  if (i = ending_pts_after_X + ending_pts_before_X) > N
    return d * blocksize + tile[i - N] + blocksize - start + 1
  else
    return d * blocksize + tile[i] - start + 1
  end
end

end
