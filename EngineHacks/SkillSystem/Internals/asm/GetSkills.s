
	.thumb

	@this hack takes r0 = character data in ram and returns a pointer to a 0-terminated list of skills (using the text buffer)
	@supports 1 personal, 1 class, 4 learned

	SkillsBuffer = 0x02026B90 @ 0x202b156 @0x202a6ac

	SkillsUnitBuffer  = 0x02026BB0
	SkillsCountBuffer = 0x02026BB4

	BWLTable = 0x0203E884

	lPersonalSkillTable  = EALiterals+0x00
	lClassSkillTable     = EALiterals+0x04
	lGetInitialSkillList = EALiterals+0x08

GetSkills:
	@ Arguments: r0 = Unit
	@ Returns:   r0 = address of skill buffer

	@ We now save what unit is used by the current buffer so that we can reuse skill lists
	@ This is in attempt to reduce lag.

	ldr r1, =SkillsUnitBuffer
	ldr r2, [r1]

	cmp r0, r2
	bne make_buffer

return_in_buffer:
	ldr r0, =SkillsBuffer
	ldr r1, =SkillsCountBuffer
	ldr r1, [r1]

	bx lr

make_buffer:
	str r0, [r1]

	push {r4-r7, lr}

	mov r4, r0            @ var r4 = unit
	ldr r5, =SkillsBuffer @ var r5 = it

	@ personal skill first, if any

	ldr  r6, [r4]
	cmp  r6, #0x00
    beq  no_personal
	ldrb r6, [r6, #0x04] @ var r6 = character id

mov r0, r4 @ unit 
bl GetAlwaysSkill
cmp r0, #0 
beq NoAlways
strb r0, [r5] 
add r5, #1 

NoAlways: 
	ldr  r2, lPersonalSkillTable
	ldrb r0, [r2, r6] @ skill byte
	cmp r0, #0
	beq no_personal
mov r1, r4 @ unit 
bl RandomizeSkill 
	cmp r0, #0
	beq no_personal

	strb r0, [r5]
	add  r5, #1

no_personal:
	@ class skill, if any

	ldr  r0, [r4, #0x04]
	ldrb r0, [r0, #0x04] @ r0 = class id

	ldr  r2, lClassSkillTable
	ldrb r0, [r2, r0] @ skill byte
	cmp r0, #0
	beq no_class
mov r1, r4 @ unit 
bl RandomizeSkill 
	cmp r0, #0
	beq no_class
	strb r0, [r5]
	add  r5, #1

no_class:
	@ learned skills, up to 4
	cmp r6, #0x46
	bhi generic_unit

	ldr r7, =BWLTable
	lsl r1, r6, #4 @ r1 = char*0x10
	add r7, r1
	add r7, #1 @start at byte 1, not 0
	mov r6, #0

lop:
	ldrb r0, [r7, r6]

	cmp  r0, #0
	beq  continue
mov r1, r4 
bl RandomizeSkill
	cmp  r0, #0
	beq  continue
	strb r0, [r5]
	add  r5, #1

continue:
	cmp r6, #3
	bge lop_end

	add r6, #1
	b lop

lop_end:
	mov  r0, #0
	strb r0, [r5]

	mov  r1, r5 @ r1 =end of skill buffer

end:
	@ return
	ldr r0, =SkillsBuffer
	sub r1, r0 @number of skills

	ldr r2, =SkillsCountBuffer
	str r1, [r2]

	pop {r4-r7}

	pop {r3}
BXR3:
	bx r3

generic_unit:
	@ call the initial skill list function

	ldr r3, lGetInitialSkillList

	mov r0, r4 @ arg r0 = unit
	mov r1, r5 @ arg r1 = output buffer

	bl BXR3

	@ implied  @ ret r0 = output buffer

	@ move to the end of the skill buffer

	mov r6, r0
	sub r6, #1 
lop_move_to_end:
add r6, #1
	ldrb r0, [r6]
	strb r0, [r6] 
	mov r1, r6 
	cmp r0, #0 
	beq end
	mov r1, r4 @ unit 
	bl RandomizeSkill
	cmp r0, #0
	beq lop_move_to_end
	strb r0, [r6] 
	
	
	b lop_move_to_end

	.pool
	.ltorg 
	.align

EALiterals:
	@ POIN lPersonalSkillTable
	@ POIN lClassSkillTable
	@ POIN (GetInitialSkillList|1)
