.text

# 0 invalid sequences
MESSAGE: 
	.asciz "()",
	.asciz "{}",
	.asciz "<>",
	.asciz "[]",
	.asciz "[]{}<>()",
	.asciz "<a{b[c(d)e]f}g>h",
	.byte 0,
