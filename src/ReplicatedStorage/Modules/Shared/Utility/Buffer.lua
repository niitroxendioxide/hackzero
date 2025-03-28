local BufferUtil = {
	__Read_Methods = {
		buffer.readi8,
		buffer.readi16,
		buffer.readf32
	},
	
	__Write_Methods = {
		buffer.writei8,
		buffer.writei16,
		buffer.writef32
	}
}

function BufferUtil:ReadFlatVector3(Buffer: buffer, Offset: number, BitSize: number?)
	BitSize = math.clamp((BitSize or 8)//8, 1, 3)
	
	local Method = BufferUtil.__Read_Methods[BitSize]
	local X = Method(Buffer, Offset)
	local Z = Method(Buffer, Offset + BitSize)
	
	return Vector3.new(X, 0, Z)
end

function BufferUtil:WriteFlatVector3(Buffer: buffer, Offset: number, Vector: Vector3, BitSize: number?)
	BitSize = math.clamp((BitSize or 8)//8, 1, 3)

	local Method = BufferUtil.__Write_Methods[BitSize]
	
	Method(Buffer, Offset, Vector.X)
	Method(Buffer, Offset + BitSize, Vector.Z)
end

return BufferUtil
