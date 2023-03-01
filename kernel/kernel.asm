
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9d013103          	ld	sp,-1584(sp) # 800089d0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	9e070713          	addi	a4,a4,-1568 # 80008a30 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	12e78793          	addi	a5,a5,302 # 80006190 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc55f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:

//
// user write()s to the console go here.
//
int consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
    int i;

    for (i = 0; i < n; i++)
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    {
        char c;
        if (either_copyin(&c, user_src, src + i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	7a0080e7          	jalr	1952(ra) # 800028ca <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
            break;
        uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
    for (i = 0; i < n; i++)
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
    }

    return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
    for (i = 0; i < n; i++)
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// copy (up to) a whole input line to dst.
// user_dist indicates whether dst is a user
// or kernel address.
//
int consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
    uint target;
    int c;
    char cbuf;

    target = n;
    80000186:	00060b1b          	sext.w	s6,a2
    acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	9e650513          	addi	a0,a0,-1562 # 80010b70 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
    while (n > 0)
    {
        // wait until interrupt handler has put some
        // input into cons.buffer.
        while (cons.r == cons.w)
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	9d648493          	addi	s1,s1,-1578 # 80010b70 <cons>
            if (killed(myproc()))
            {
                release(&cons.lock);
                return -1;
            }
            sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	a6690913          	addi	s2,s2,-1434 # 80010c08 <cons+0x98>
        }

        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

        if (c == C('D'))
    800001aa:	4b91                	li	s7,4
            break;
        }

        // copy the input byte to the user-space buffer.
        cbuf = c;
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
            break;

        dst++;
        --n;

        if (c == '\n')
    800001ae:	4ca9                	li	s9,10
    while (n > 0)
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
        while (cons.r == cons.w)
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
            if (killed(myproc()))
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	8ca080e7          	jalr	-1846(ra) # 80001a8a <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	54c080e7          	jalr	1356(ra) # 80002714 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
            sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	296080e7          	jalr	662(ra) # 8000246c <sleep>
        while (cons.r == cons.w)
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
        c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
        if (c == C('D'))
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
        cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
        if (either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	662080e7          	jalr	1634(ra) # 80002874 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
        dst++;
    8000021e:	0a05                	addi	s4,s4,1
        --n;
    80000220:	39fd                	addiw	s3,s3,-1
        if (c == '\n')
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
            // a whole line has arrived, return to
            // the user-level read().
            break;
        }
    }
    release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	94a50513          	addi	a0,a0,-1718 # 80010b70 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

    return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
                release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	93450513          	addi	a0,a0,-1740 # 80010b70 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
                return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
            if (n < target)
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
                cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	98f72b23          	sw	a5,-1642(a4) # 80010c08 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
    if (c == BACKSPACE)
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
        uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
        uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
        uartputc_sync(' ');
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
        uartputc_sync('\b');
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// uartintr() calls this for input character.
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
    acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	8a450513          	addi	a0,a0,-1884 # 80010b70 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

    switch (c)
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
    {
    case C('P'): // Print process list.
        procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	62e080e7          	jalr	1582(ra) # 80002920 <procdump>
            }
        }
        break;
    }

    release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	87650513          	addi	a0,a0,-1930 # 80010b70 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
    switch (c)
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	85270713          	addi	a4,a4,-1966 # 80010b70 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
            c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
            consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	82878793          	addi	a5,a5,-2008 # 80010b70 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
            if (c == '\n' || c == C('D') || cons.e - cons.r == INPUT_BUF_SIZE)
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	8927a783          	lw	a5,-1902(a5) # 80010c08 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
        while (cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	7e670713          	addi	a4,a4,2022 # 80010b70 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	7d648493          	addi	s1,s1,2006 # 80010b70 <cons>
        while (cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
               cons.buf[(cons.e - 1) % INPUT_BUF_SIZE] != '\n')
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
        while (cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
            cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
            consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
        while (cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
        if (cons.e != cons.w)
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	79a70713          	addi	a4,a4,1946 # 80010b70 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
            cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	82f72223          	sw	a5,-2012(a4) # 80010c10 <cons+0xa0>
            consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
        if (c != 0 && cons.e - cons.r < INPUT_BUF_SIZE)
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
            consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
            cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	75e78793          	addi	a5,a5,1886 # 80010b70 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
                cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	7cc7ab23          	sw	a2,2006(a5) # 80010c0c <cons+0x9c>
                wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	7ca50513          	addi	a0,a0,1994 # 80010c08 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	08a080e7          	jalr	138(ra) # 800024d0 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
    initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	71050513          	addi	a0,a0,1808 # 80010b70 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

    uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

    // connect read and write system calls
    // to consoleread and consolewrite.
    devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	c9078793          	addi	a5,a5,-880 # 80021108 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
    devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	6e07a223          	sw	zero,1764(a5) # 80010c30 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	46f72823          	sw	a5,1136(a4) # 800089f0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	674dad83          	lw	s11,1652(s11) # 80010c30 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	61e50513          	addi	a0,a0,1566 # 80010c18 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	4c050513          	addi	a0,a0,1216 # 80010c18 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	4a448493          	addi	s1,s1,1188 # 80010c18 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	46450513          	addi	a0,a0,1124 # 80010c38 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	1f07a783          	lw	a5,496(a5) # 800089f0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	1c07b783          	ld	a5,448(a5) # 800089f8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	1c073703          	ld	a4,448(a4) # 80008a00 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	3d6a0a13          	addi	s4,s4,982 # 80010c38 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	18e48493          	addi	s1,s1,398 # 800089f8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	18e98993          	addi	s3,s3,398 # 80008a00 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	c3c080e7          	jalr	-964(ra) # 800024d0 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	36850513          	addi	a0,a0,872 # 80010c38 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	1107a783          	lw	a5,272(a5) # 800089f0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	11673703          	ld	a4,278(a4) # 80008a00 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1067b783          	ld	a5,262(a5) # 800089f8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	33a98993          	addi	s3,s3,826 # 80010c38 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	0f248493          	addi	s1,s1,242 # 800089f8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	0f290913          	addi	s2,s2,242 # 80008a00 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	b4e080e7          	jalr	-1202(ra) # 8000246c <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	30448493          	addi	s1,s1,772 # 80010c38 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	0ae7bc23          	sd	a4,184(a5) # 80008a00 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	27e48493          	addi	s1,s1,638 # 80010c38 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	8a478793          	addi	a5,a5,-1884 # 800222a0 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	25490913          	addi	s2,s2,596 # 80010c70 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	1b650513          	addi	a0,a0,438 # 80010c70 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	7d250513          	addi	a0,a0,2002 # 800222a0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	18048493          	addi	s1,s1,384 # 80010c70 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	16850513          	addi	a0,a0,360 # 80010c70 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	13c50513          	addi	a0,a0,316 # 80010c70 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	efe080e7          	jalr	-258(ra) # 80001a6e <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	ecc080e7          	jalr	-308(ra) # 80001a6e <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	ec0080e7          	jalr	-320(ra) # 80001a6e <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	ea8080e7          	jalr	-344(ra) # 80001a6e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	e68080e7          	jalr	-408(ra) # 80001a6e <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	e3c080e7          	jalr	-452(ra) # 80001a6e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdcd61>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	bde080e7          	jalr	-1058(ra) # 80001a5e <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	b8070713          	addi	a4,a4,-1152 # 80008a08 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	bc2080e7          	jalr	-1086(ra) # 80001a5e <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	cea080e7          	jalr	-790(ra) # 80002ba8 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	30a080e7          	jalr	778(ra) # 800061d0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	206080e7          	jalr	518(ra) # 800020d4 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	a4e080e7          	jalr	-1458(ra) # 8000197c <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	c4a080e7          	jalr	-950(ra) # 80002b80 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	c6a080e7          	jalr	-918(ra) # 80002ba8 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	274080e7          	jalr	628(ra) # 800061ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	282080e7          	jalr	642(ra) # 800061d0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	41e080e7          	jalr	1054(ra) # 80003374 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	abe080e7          	jalr	-1346(ra) # 80003a1c <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	a64080e7          	jalr	-1436(ra) # 800049ca <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	36a080e7          	jalr	874(ra) # 800062d8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	df0080e7          	jalr	-528(ra) # 80001d66 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	a8f72223          	sw	a5,-1404(a4) # 80008a08 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	a787b783          	ld	a5,-1416(a5) # 80008a10 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdcd57>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	6b8080e7          	jalr	1720(ra) # 800018e6 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	7aa7be23          	sd	a0,1980(a5) # 80008a10 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdcd60>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <rr_scheduler>:
        (*sched_pointer)();
    }
}

void rr_scheduler(void)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
  asm volatile("mv %0, tp" : "=r" (x) );
    8000184a:	8792                	mv	a5,tp
    int id = r_tp();
    8000184c:	2781                	sext.w	a5,a5
    struct proc *p;
    struct cpu *c = mycpu();

    c->proc = 0;
    8000184e:	0000fa97          	auipc	s5,0xf
    80001852:	442a8a93          	addi	s5,s5,1090 # 80010c90 <cpus>
    80001856:	00779713          	slli	a4,a5,0x7
    8000185a:	00ea86b3          	add	a3,s5,a4
    8000185e:	0006b023          	sd	zero,0(a3) # fffffffffffff000 <end+0xffffffff7ffdcd60>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001862:	100026f3          	csrr	a3,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001866:	0026e693          	ori	a3,a3,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000186a:	10069073          	csrw	sstatus,a3
            // Switch to chosen process.  It is the process's job
            // to release its lock and then reacquire it
            // before jumping back to us.
            p->state = RUNNING;
            c->proc = p;
            swtch(&c->context, &p->context);
    8000186e:	0721                	addi	a4,a4,8
    80001870:	9aba                	add	s5,s5,a4
    for (p = proc; p < &proc[NPROC]; p++)
    80001872:	00010497          	auipc	s1,0x10
    80001876:	84e48493          	addi	s1,s1,-1970 # 800110c0 <proc>
        if (p->state == RUNNABLE)
    8000187a:	498d                	li	s3,3
            p->state = RUNNING;
    8000187c:	4b11                	li	s6,4
            c->proc = p;
    8000187e:	079e                	slli	a5,a5,0x7
    80001880:	0000fa17          	auipc	s4,0xf
    80001884:	410a0a13          	addi	s4,s4,1040 # 80010c90 <cpus>
    80001888:	9a3e                	add	s4,s4,a5
    for (p = proc; p < &proc[NPROC]; p++)
    8000188a:	00015917          	auipc	s2,0x15
    8000188e:	63690913          	addi	s2,s2,1590 # 80016ec0 <tickslock>
    80001892:	a811                	j	800018a6 <rr_scheduler+0x70>

            // Process is done running for now.
            // It should have changed its p->state before coming back.
            c->proc = 0;
        }
        release(&p->lock);
    80001894:	8526                	mv	a0,s1
    80001896:	fffff097          	auipc	ra,0xfffff
    8000189a:	3f4080e7          	jalr	1012(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    8000189e:	17848493          	addi	s1,s1,376
    800018a2:	03248863          	beq	s1,s2,800018d2 <rr_scheduler+0x9c>
        acquire(&p->lock);
    800018a6:	8526                	mv	a0,s1
    800018a8:	fffff097          	auipc	ra,0xfffff
    800018ac:	32e080e7          	jalr	814(ra) # 80000bd6 <acquire>
        if (p->state == RUNNABLE)
    800018b0:	4c9c                	lw	a5,24(s1)
    800018b2:	ff3791e3          	bne	a5,s3,80001894 <rr_scheduler+0x5e>
            p->state = RUNNING;
    800018b6:	0164ac23          	sw	s6,24(s1)
            c->proc = p;
    800018ba:	009a3023          	sd	s1,0(s4)
            swtch(&c->context, &p->context);
    800018be:	07048593          	addi	a1,s1,112
    800018c2:	8556                	mv	a0,s5
    800018c4:	00001097          	auipc	ra,0x1
    800018c8:	252080e7          	jalr	594(ra) # 80002b16 <swtch>
            c->proc = 0;
    800018cc:	000a3023          	sd	zero,0(s4)
    800018d0:	b7d1                	j	80001894 <rr_scheduler+0x5e>
    }
    // In case a setsched happened, we will switch to the new scheduler after one
    // Round Robin round has completed.
}
    800018d2:	70e2                	ld	ra,56(sp)
    800018d4:	7442                	ld	s0,48(sp)
    800018d6:	74a2                	ld	s1,40(sp)
    800018d8:	7902                	ld	s2,32(sp)
    800018da:	69e2                	ld	s3,24(sp)
    800018dc:	6a42                	ld	s4,16(sp)
    800018de:	6aa2                	ld	s5,8(sp)
    800018e0:	6b02                	ld	s6,0(sp)
    800018e2:	6121                	addi	sp,sp,64
    800018e4:	8082                	ret

00000000800018e6 <proc_mapstacks>:
{
    800018e6:	7139                	addi	sp,sp,-64
    800018e8:	fc06                	sd	ra,56(sp)
    800018ea:	f822                	sd	s0,48(sp)
    800018ec:	f426                	sd	s1,40(sp)
    800018ee:	f04a                	sd	s2,32(sp)
    800018f0:	ec4e                	sd	s3,24(sp)
    800018f2:	e852                	sd	s4,16(sp)
    800018f4:	e456                	sd	s5,8(sp)
    800018f6:	e05a                	sd	s6,0(sp)
    800018f8:	0080                	addi	s0,sp,64
    800018fa:	89aa                	mv	s3,a0
    for (p = proc; p < &proc[NPROC]; p++)
    800018fc:	0000f497          	auipc	s1,0xf
    80001900:	7c448493          	addi	s1,s1,1988 # 800110c0 <proc>
        uint64 va = KSTACK((int)(p - proc));
    80001904:	8b26                	mv	s6,s1
    80001906:	00006a97          	auipc	s5,0x6
    8000190a:	6faa8a93          	addi	s5,s5,1786 # 80008000 <etext>
    8000190e:	04000937          	lui	s2,0x4000
    80001912:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001914:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    80001916:	00015a17          	auipc	s4,0x15
    8000191a:	5aaa0a13          	addi	s4,s4,1450 # 80016ec0 <tickslock>
        char *pa = kalloc();
    8000191e:	fffff097          	auipc	ra,0xfffff
    80001922:	1c8080e7          	jalr	456(ra) # 80000ae6 <kalloc>
    80001926:	862a                	mv	a2,a0
        if (pa == 0)
    80001928:	c131                	beqz	a0,8000196c <proc_mapstacks+0x86>
        uint64 va = KSTACK((int)(p - proc));
    8000192a:	416485b3          	sub	a1,s1,s6
    8000192e:	858d                	srai	a1,a1,0x3
    80001930:	000ab783          	ld	a5,0(s5)
    80001934:	02f585b3          	mul	a1,a1,a5
    80001938:	2585                	addiw	a1,a1,1
    8000193a:	00d5959b          	slliw	a1,a1,0xd
        kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000193e:	4719                	li	a4,6
    80001940:	6685                	lui	a3,0x1
    80001942:	40b905b3          	sub	a1,s2,a1
    80001946:	854e                	mv	a0,s3
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	7f6080e7          	jalr	2038(ra) # 8000113e <kvmmap>
    for (p = proc; p < &proc[NPROC]; p++)
    80001950:	17848493          	addi	s1,s1,376
    80001954:	fd4495e3          	bne	s1,s4,8000191e <proc_mapstacks+0x38>
}
    80001958:	70e2                	ld	ra,56(sp)
    8000195a:	7442                	ld	s0,48(sp)
    8000195c:	74a2                	ld	s1,40(sp)
    8000195e:	7902                	ld	s2,32(sp)
    80001960:	69e2                	ld	s3,24(sp)
    80001962:	6a42                	ld	s4,16(sp)
    80001964:	6aa2                	ld	s5,8(sp)
    80001966:	6b02                	ld	s6,0(sp)
    80001968:	6121                	addi	sp,sp,64
    8000196a:	8082                	ret
            panic("kalloc");
    8000196c:	00007517          	auipc	a0,0x7
    80001970:	86c50513          	addi	a0,a0,-1940 # 800081d8 <digits+0x198>
    80001974:	fffff097          	auipc	ra,0xfffff
    80001978:	bcc080e7          	jalr	-1076(ra) # 80000540 <panic>

000000008000197c <procinit>:
{
    8000197c:	7139                	addi	sp,sp,-64
    8000197e:	fc06                	sd	ra,56(sp)
    80001980:	f822                	sd	s0,48(sp)
    80001982:	f426                	sd	s1,40(sp)
    80001984:	f04a                	sd	s2,32(sp)
    80001986:	ec4e                	sd	s3,24(sp)
    80001988:	e852                	sd	s4,16(sp)
    8000198a:	e456                	sd	s5,8(sp)
    8000198c:	e05a                	sd	s6,0(sp)
    8000198e:	0080                	addi	s0,sp,64
    initlock(&pid_lock, "nextpid");
    80001990:	00007597          	auipc	a1,0x7
    80001994:	85058593          	addi	a1,a1,-1968 # 800081e0 <digits+0x1a0>
    80001998:	0000f517          	auipc	a0,0xf
    8000199c:	6f850513          	addi	a0,a0,1784 # 80011090 <pid_lock>
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	1a6080e7          	jalr	422(ra) # 80000b46 <initlock>
    initlock(&wait_lock, "wait_lock");
    800019a8:	00007597          	auipc	a1,0x7
    800019ac:	84058593          	addi	a1,a1,-1984 # 800081e8 <digits+0x1a8>
    800019b0:	0000f517          	auipc	a0,0xf
    800019b4:	6f850513          	addi	a0,a0,1784 # 800110a8 <wait_lock>
    800019b8:	fffff097          	auipc	ra,0xfffff
    800019bc:	18e080e7          	jalr	398(ra) # 80000b46 <initlock>
    for (p = proc; p < &proc[NPROC]; p++)
    800019c0:	0000f497          	auipc	s1,0xf
    800019c4:	70048493          	addi	s1,s1,1792 # 800110c0 <proc>
        initlock(&p->lock, "proc");
    800019c8:	00007b17          	auipc	s6,0x7
    800019cc:	830b0b13          	addi	s6,s6,-2000 # 800081f8 <digits+0x1b8>
        p->kstack = KSTACK((int)(p - proc));
    800019d0:	8aa6                	mv	s5,s1
    800019d2:	00006a17          	auipc	s4,0x6
    800019d6:	62ea0a13          	addi	s4,s4,1582 # 80008000 <etext>
    800019da:	04000937          	lui	s2,0x4000
    800019de:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800019e0:	0932                	slli	s2,s2,0xc
    for (p = proc; p < &proc[NPROC]; p++)
    800019e2:	00015997          	auipc	s3,0x15
    800019e6:	4de98993          	addi	s3,s3,1246 # 80016ec0 <tickslock>
        initlock(&p->lock, "proc");
    800019ea:	85da                	mv	a1,s6
    800019ec:	8526                	mv	a0,s1
    800019ee:	fffff097          	auipc	ra,0xfffff
    800019f2:	158080e7          	jalr	344(ra) # 80000b46 <initlock>
        p->state = UNUSED;
    800019f6:	0004ac23          	sw	zero,24(s1)
        p->kstack = KSTACK((int)(p - proc));
    800019fa:	415487b3          	sub	a5,s1,s5
    800019fe:	878d                	srai	a5,a5,0x3
    80001a00:	000a3703          	ld	a4,0(s4)
    80001a04:	02e787b3          	mul	a5,a5,a4
    80001a08:	2785                	addiw	a5,a5,1
    80001a0a:	00d7979b          	slliw	a5,a5,0xd
    80001a0e:	40f907b3          	sub	a5,s2,a5
    80001a12:	e8bc                	sd	a5,80(s1)
    for (p = proc; p < &proc[NPROC]; p++)
    80001a14:	17848493          	addi	s1,s1,376
    80001a18:	fd3499e3          	bne	s1,s3,800019ea <procinit+0x6e>
}
    80001a1c:	70e2                	ld	ra,56(sp)
    80001a1e:	7442                	ld	s0,48(sp)
    80001a20:	74a2                	ld	s1,40(sp)
    80001a22:	7902                	ld	s2,32(sp)
    80001a24:	69e2                	ld	s3,24(sp)
    80001a26:	6a42                	ld	s4,16(sp)
    80001a28:	6aa2                	ld	s5,8(sp)
    80001a2a:	6b02                	ld	s6,0(sp)
    80001a2c:	6121                	addi	sp,sp,64
    80001a2e:	8082                	ret

0000000080001a30 <copy_array>:
{
    80001a30:	1141                	addi	sp,sp,-16
    80001a32:	e422                	sd	s0,8(sp)
    80001a34:	0800                	addi	s0,sp,16
    for (int i = 0; i < len; i++)
    80001a36:	02c05163          	blez	a2,80001a58 <copy_array+0x28>
    80001a3a:	87aa                	mv	a5,a0
    80001a3c:	0505                	addi	a0,a0,1
    80001a3e:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    80001a40:	1602                	slli	a2,a2,0x20
    80001a42:	9201                	srli	a2,a2,0x20
    80001a44:	00c506b3          	add	a3,a0,a2
        dst[i] = src[i];
    80001a48:	0007c703          	lbu	a4,0(a5)
    80001a4c:	00e58023          	sb	a4,0(a1)
    for (int i = 0; i < len; i++)
    80001a50:	0785                	addi	a5,a5,1
    80001a52:	0585                	addi	a1,a1,1
    80001a54:	fed79ae3          	bne	a5,a3,80001a48 <copy_array+0x18>
}
    80001a58:	6422                	ld	s0,8(sp)
    80001a5a:	0141                	addi	sp,sp,16
    80001a5c:	8082                	ret

0000000080001a5e <cpuid>:
{
    80001a5e:	1141                	addi	sp,sp,-16
    80001a60:	e422                	sd	s0,8(sp)
    80001a62:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a64:	8512                	mv	a0,tp
}
    80001a66:	2501                	sext.w	a0,a0
    80001a68:	6422                	ld	s0,8(sp)
    80001a6a:	0141                	addi	sp,sp,16
    80001a6c:	8082                	ret

0000000080001a6e <mycpu>:
{
    80001a6e:	1141                	addi	sp,sp,-16
    80001a70:	e422                	sd	s0,8(sp)
    80001a72:	0800                	addi	s0,sp,16
    80001a74:	8792                	mv	a5,tp
    struct cpu *c = &cpus[id];
    80001a76:	2781                	sext.w	a5,a5
    80001a78:	079e                	slli	a5,a5,0x7
}
    80001a7a:	0000f517          	auipc	a0,0xf
    80001a7e:	21650513          	addi	a0,a0,534 # 80010c90 <cpus>
    80001a82:	953e                	add	a0,a0,a5
    80001a84:	6422                	ld	s0,8(sp)
    80001a86:	0141                	addi	sp,sp,16
    80001a88:	8082                	ret

0000000080001a8a <myproc>:
{
    80001a8a:	1101                	addi	sp,sp,-32
    80001a8c:	ec06                	sd	ra,24(sp)
    80001a8e:	e822                	sd	s0,16(sp)
    80001a90:	e426                	sd	s1,8(sp)
    80001a92:	1000                	addi	s0,sp,32
    push_off();
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	0f6080e7          	jalr	246(ra) # 80000b8a <push_off>
    80001a9c:	8792                	mv	a5,tp
    struct proc *p = c->proc;
    80001a9e:	2781                	sext.w	a5,a5
    80001aa0:	079e                	slli	a5,a5,0x7
    80001aa2:	0000f717          	auipc	a4,0xf
    80001aa6:	1ee70713          	addi	a4,a4,494 # 80010c90 <cpus>
    80001aaa:	97ba                	add	a5,a5,a4
    80001aac:	6384                	ld	s1,0(a5)
    pop_off();
    80001aae:	fffff097          	auipc	ra,0xfffff
    80001ab2:	17c080e7          	jalr	380(ra) # 80000c2a <pop_off>
}
    80001ab6:	8526                	mv	a0,s1
    80001ab8:	60e2                	ld	ra,24(sp)
    80001aba:	6442                	ld	s0,16(sp)
    80001abc:	64a2                	ld	s1,8(sp)
    80001abe:	6105                	addi	sp,sp,32
    80001ac0:	8082                	ret

0000000080001ac2 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001ac2:	1141                	addi	sp,sp,-16
    80001ac4:	e406                	sd	ra,8(sp)
    80001ac6:	e022                	sd	s0,0(sp)
    80001ac8:	0800                	addi	s0,sp,16
    static int first = 1;

    // Still holding p->lock from scheduler.
    release(&myproc()->lock);
    80001aca:	00000097          	auipc	ra,0x0
    80001ace:	fc0080e7          	jalr	-64(ra) # 80001a8a <myproc>
    80001ad2:	fffff097          	auipc	ra,0xfffff
    80001ad6:	1b8080e7          	jalr	440(ra) # 80000c8a <release>

    if (first)
    80001ada:	00007797          	auipc	a5,0x7
    80001ade:	e567a783          	lw	a5,-426(a5) # 80008930 <first.1>
    80001ae2:	eb89                	bnez	a5,80001af4 <forkret+0x32>
        // be run from main().
        first = 0;
        fsinit(ROOTDEV);
    }

    usertrapret();
    80001ae4:	00001097          	auipc	ra,0x1
    80001ae8:	0dc080e7          	jalr	220(ra) # 80002bc0 <usertrapret>
}
    80001aec:	60a2                	ld	ra,8(sp)
    80001aee:	6402                	ld	s0,0(sp)
    80001af0:	0141                	addi	sp,sp,16
    80001af2:	8082                	ret
        first = 0;
    80001af4:	00007797          	auipc	a5,0x7
    80001af8:	e207ae23          	sw	zero,-452(a5) # 80008930 <first.1>
        fsinit(ROOTDEV);
    80001afc:	4505                	li	a0,1
    80001afe:	00002097          	auipc	ra,0x2
    80001b02:	e9e080e7          	jalr	-354(ra) # 8000399c <fsinit>
    80001b06:	bff9                	j	80001ae4 <forkret+0x22>

0000000080001b08 <allocpid>:
{
    80001b08:	1101                	addi	sp,sp,-32
    80001b0a:	ec06                	sd	ra,24(sp)
    80001b0c:	e822                	sd	s0,16(sp)
    80001b0e:	e426                	sd	s1,8(sp)
    80001b10:	e04a                	sd	s2,0(sp)
    80001b12:	1000                	addi	s0,sp,32
    acquire(&pid_lock);
    80001b14:	0000f917          	auipc	s2,0xf
    80001b18:	57c90913          	addi	s2,s2,1404 # 80011090 <pid_lock>
    80001b1c:	854a                	mv	a0,s2
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	0b8080e7          	jalr	184(ra) # 80000bd6 <acquire>
    pid = nextpid;
    80001b26:	00007797          	auipc	a5,0x7
    80001b2a:	e1a78793          	addi	a5,a5,-486 # 80008940 <nextpid>
    80001b2e:	4384                	lw	s1,0(a5)
    nextpid = nextpid + 1;
    80001b30:	0014871b          	addiw	a4,s1,1
    80001b34:	c398                	sw	a4,0(a5)
    release(&pid_lock);
    80001b36:	854a                	mv	a0,s2
    80001b38:	fffff097          	auipc	ra,0xfffff
    80001b3c:	152080e7          	jalr	338(ra) # 80000c8a <release>
}
    80001b40:	8526                	mv	a0,s1
    80001b42:	60e2                	ld	ra,24(sp)
    80001b44:	6442                	ld	s0,16(sp)
    80001b46:	64a2                	ld	s1,8(sp)
    80001b48:	6902                	ld	s2,0(sp)
    80001b4a:	6105                	addi	sp,sp,32
    80001b4c:	8082                	ret

0000000080001b4e <proc_pagetable>:
{
    80001b4e:	1101                	addi	sp,sp,-32
    80001b50:	ec06                	sd	ra,24(sp)
    80001b52:	e822                	sd	s0,16(sp)
    80001b54:	e426                	sd	s1,8(sp)
    80001b56:	e04a                	sd	s2,0(sp)
    80001b58:	1000                	addi	s0,sp,32
    80001b5a:	892a                	mv	s2,a0
    pagetable = uvmcreate();
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	7cc080e7          	jalr	1996(ra) # 80001328 <uvmcreate>
    80001b64:	84aa                	mv	s1,a0
    if (pagetable == 0)
    80001b66:	c121                	beqz	a0,80001ba6 <proc_pagetable+0x58>
    if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b68:	4729                	li	a4,10
    80001b6a:	00005697          	auipc	a3,0x5
    80001b6e:	49668693          	addi	a3,a3,1174 # 80007000 <_trampoline>
    80001b72:	6605                	lui	a2,0x1
    80001b74:	040005b7          	lui	a1,0x4000
    80001b78:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b7a:	05b2                	slli	a1,a1,0xc
    80001b7c:	fffff097          	auipc	ra,0xfffff
    80001b80:	522080e7          	jalr	1314(ra) # 8000109e <mappages>
    80001b84:	02054863          	bltz	a0,80001bb4 <proc_pagetable+0x66>
    if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b88:	4719                	li	a4,6
    80001b8a:	06893683          	ld	a3,104(s2)
    80001b8e:	6605                	lui	a2,0x1
    80001b90:	020005b7          	lui	a1,0x2000
    80001b94:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b96:	05b6                	slli	a1,a1,0xd
    80001b98:	8526                	mv	a0,s1
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	504080e7          	jalr	1284(ra) # 8000109e <mappages>
    80001ba2:	02054163          	bltz	a0,80001bc4 <proc_pagetable+0x76>
}
    80001ba6:	8526                	mv	a0,s1
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret
        uvmfree(pagetable, 0);
    80001bb4:	4581                	li	a1,0
    80001bb6:	8526                	mv	a0,s1
    80001bb8:	00000097          	auipc	ra,0x0
    80001bbc:	976080e7          	jalr	-1674(ra) # 8000152e <uvmfree>
        return 0;
    80001bc0:	4481                	li	s1,0
    80001bc2:	b7d5                	j	80001ba6 <proc_pagetable+0x58>
        uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bc4:	4681                	li	a3,0
    80001bc6:	4605                	li	a2,1
    80001bc8:	040005b7          	lui	a1,0x4000
    80001bcc:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001bce:	05b2                	slli	a1,a1,0xc
    80001bd0:	8526                	mv	a0,s1
    80001bd2:	fffff097          	auipc	ra,0xfffff
    80001bd6:	692080e7          	jalr	1682(ra) # 80001264 <uvmunmap>
        uvmfree(pagetable, 0);
    80001bda:	4581                	li	a1,0
    80001bdc:	8526                	mv	a0,s1
    80001bde:	00000097          	auipc	ra,0x0
    80001be2:	950080e7          	jalr	-1712(ra) # 8000152e <uvmfree>
        return 0;
    80001be6:	4481                	li	s1,0
    80001be8:	bf7d                	j	80001ba6 <proc_pagetable+0x58>

0000000080001bea <proc_freepagetable>:
{
    80001bea:	1101                	addi	sp,sp,-32
    80001bec:	ec06                	sd	ra,24(sp)
    80001bee:	e822                	sd	s0,16(sp)
    80001bf0:	e426                	sd	s1,8(sp)
    80001bf2:	e04a                	sd	s2,0(sp)
    80001bf4:	1000                	addi	s0,sp,32
    80001bf6:	84aa                	mv	s1,a0
    80001bf8:	892e                	mv	s2,a1
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bfa:	4681                	li	a3,0
    80001bfc:	4605                	li	a2,1
    80001bfe:	040005b7          	lui	a1,0x4000
    80001c02:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001c04:	05b2                	slli	a1,a1,0xc
    80001c06:	fffff097          	auipc	ra,0xfffff
    80001c0a:	65e080e7          	jalr	1630(ra) # 80001264 <uvmunmap>
    uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c0e:	4681                	li	a3,0
    80001c10:	4605                	li	a2,1
    80001c12:	020005b7          	lui	a1,0x2000
    80001c16:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001c18:	05b6                	slli	a1,a1,0xd
    80001c1a:	8526                	mv	a0,s1
    80001c1c:	fffff097          	auipc	ra,0xfffff
    80001c20:	648080e7          	jalr	1608(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, sz);
    80001c24:	85ca                	mv	a1,s2
    80001c26:	8526                	mv	a0,s1
    80001c28:	00000097          	auipc	ra,0x0
    80001c2c:	906080e7          	jalr	-1786(ra) # 8000152e <uvmfree>
}
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret

0000000080001c3c <freeproc>:
{
    80001c3c:	1101                	addi	sp,sp,-32
    80001c3e:	ec06                	sd	ra,24(sp)
    80001c40:	e822                	sd	s0,16(sp)
    80001c42:	e426                	sd	s1,8(sp)
    80001c44:	1000                	addi	s0,sp,32
    80001c46:	84aa                	mv	s1,a0
    if (p->trapframe)
    80001c48:	7528                	ld	a0,104(a0)
    80001c4a:	c509                	beqz	a0,80001c54 <freeproc+0x18>
        kfree((void *)p->trapframe);
    80001c4c:	fffff097          	auipc	ra,0xfffff
    80001c50:	d9c080e7          	jalr	-612(ra) # 800009e8 <kfree>
    p->trapframe = 0;
    80001c54:	0604b423          	sd	zero,104(s1)
    if (p->pagetable)
    80001c58:	70a8                	ld	a0,96(s1)
    80001c5a:	c511                	beqz	a0,80001c66 <freeproc+0x2a>
        proc_freepagetable(p->pagetable, p->sz);
    80001c5c:	6cac                	ld	a1,88(s1)
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	f8c080e7          	jalr	-116(ra) # 80001bea <proc_freepagetable>
    p->pagetable = 0;
    80001c66:	0604b023          	sd	zero,96(s1)
    p->sz = 0;
    80001c6a:	0404bc23          	sd	zero,88(s1)
    p->pid = 0;
    80001c6e:	0204a823          	sw	zero,48(s1)
    p->parent = 0;
    80001c72:	0404b423          	sd	zero,72(s1)
    p->name[0] = 0;
    80001c76:	16048423          	sb	zero,360(s1)
    p->chan = 0;
    80001c7a:	0204b023          	sd	zero,32(s1)
    p->killed = 0;
    80001c7e:	0204a423          	sw	zero,40(s1)
    p->xstate = 0;
    80001c82:	0204a623          	sw	zero,44(s1)
    p->state = UNUSED;
    80001c86:	0004ac23          	sw	zero,24(s1)
}
    80001c8a:	60e2                	ld	ra,24(sp)
    80001c8c:	6442                	ld	s0,16(sp)
    80001c8e:	64a2                	ld	s1,8(sp)
    80001c90:	6105                	addi	sp,sp,32
    80001c92:	8082                	ret

0000000080001c94 <allocproc>:
{
    80001c94:	1101                	addi	sp,sp,-32
    80001c96:	ec06                	sd	ra,24(sp)
    80001c98:	e822                	sd	s0,16(sp)
    80001c9a:	e426                	sd	s1,8(sp)
    80001c9c:	e04a                	sd	s2,0(sp)
    80001c9e:	1000                	addi	s0,sp,32
    for (p = proc; p < &proc[NPROC]; p++)
    80001ca0:	0000f497          	auipc	s1,0xf
    80001ca4:	42048493          	addi	s1,s1,1056 # 800110c0 <proc>
    80001ca8:	00015917          	auipc	s2,0x15
    80001cac:	21890913          	addi	s2,s2,536 # 80016ec0 <tickslock>
        acquire(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	f24080e7          	jalr	-220(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80001cba:	4c9c                	lw	a5,24(s1)
    80001cbc:	cf81                	beqz	a5,80001cd4 <allocproc+0x40>
            release(&p->lock);
    80001cbe:	8526                	mv	a0,s1
    80001cc0:	fffff097          	auipc	ra,0xfffff
    80001cc4:	fca080e7          	jalr	-54(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80001cc8:	17848493          	addi	s1,s1,376
    80001ccc:	ff2492e3          	bne	s1,s2,80001cb0 <allocproc+0x1c>
    return 0;
    80001cd0:	4481                	li	s1,0
    80001cd2:	a899                	j	80001d28 <allocproc+0x94>
    p->pid = allocpid();
    80001cd4:	00000097          	auipc	ra,0x0
    80001cd8:	e34080e7          	jalr	-460(ra) # 80001b08 <allocpid>
    80001cdc:	d888                	sw	a0,48(s1)
    p->state = USED;
    80001cde:	4785                	li	a5,1
    80001ce0:	cc9c                	sw	a5,24(s1)
    p->tics = 0;
    80001ce2:	0204aa23          	sw	zero,52(s1)
    if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001ce6:	fffff097          	auipc	ra,0xfffff
    80001cea:	e00080e7          	jalr	-512(ra) # 80000ae6 <kalloc>
    80001cee:	892a                	mv	s2,a0
    80001cf0:	f4a8                	sd	a0,104(s1)
    80001cf2:	c131                	beqz	a0,80001d36 <allocproc+0xa2>
    p->pagetable = proc_pagetable(p);
    80001cf4:	8526                	mv	a0,s1
    80001cf6:	00000097          	auipc	ra,0x0
    80001cfa:	e58080e7          	jalr	-424(ra) # 80001b4e <proc_pagetable>
    80001cfe:	892a                	mv	s2,a0
    80001d00:	f0a8                	sd	a0,96(s1)
    if (p->pagetable == 0)
    80001d02:	c531                	beqz	a0,80001d4e <allocproc+0xba>
    memset(&p->context, 0, sizeof(p->context));
    80001d04:	07000613          	li	a2,112
    80001d08:	4581                	li	a1,0
    80001d0a:	07048513          	addi	a0,s1,112
    80001d0e:	fffff097          	auipc	ra,0xfffff
    80001d12:	fc4080e7          	jalr	-60(ra) # 80000cd2 <memset>
    p->context.ra = (uint64)forkret;
    80001d16:	00000797          	auipc	a5,0x0
    80001d1a:	dac78793          	addi	a5,a5,-596 # 80001ac2 <forkret>
    80001d1e:	f8bc                	sd	a5,112(s1)
    p->context.sp = p->kstack + PGSIZE;
    80001d20:	68bc                	ld	a5,80(s1)
    80001d22:	6705                	lui	a4,0x1
    80001d24:	97ba                	add	a5,a5,a4
    80001d26:	fcbc                	sd	a5,120(s1)
}
    80001d28:	8526                	mv	a0,s1
    80001d2a:	60e2                	ld	ra,24(sp)
    80001d2c:	6442                	ld	s0,16(sp)
    80001d2e:	64a2                	ld	s1,8(sp)
    80001d30:	6902                	ld	s2,0(sp)
    80001d32:	6105                	addi	sp,sp,32
    80001d34:	8082                	ret
        freeproc(p);
    80001d36:	8526                	mv	a0,s1
    80001d38:	00000097          	auipc	ra,0x0
    80001d3c:	f04080e7          	jalr	-252(ra) # 80001c3c <freeproc>
        release(&p->lock);
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f48080e7          	jalr	-184(ra) # 80000c8a <release>
        return 0;
    80001d4a:	84ca                	mv	s1,s2
    80001d4c:	bff1                	j	80001d28 <allocproc+0x94>
        freeproc(p);
    80001d4e:	8526                	mv	a0,s1
    80001d50:	00000097          	auipc	ra,0x0
    80001d54:	eec080e7          	jalr	-276(ra) # 80001c3c <freeproc>
        release(&p->lock);
    80001d58:	8526                	mv	a0,s1
    80001d5a:	fffff097          	auipc	ra,0xfffff
    80001d5e:	f30080e7          	jalr	-208(ra) # 80000c8a <release>
        return 0;
    80001d62:	84ca                	mv	s1,s2
    80001d64:	b7d1                	j	80001d28 <allocproc+0x94>

0000000080001d66 <userinit>:
{
    80001d66:	1101                	addi	sp,sp,-32
    80001d68:	ec06                	sd	ra,24(sp)
    80001d6a:	e822                	sd	s0,16(sp)
    80001d6c:	e426                	sd	s1,8(sp)
    80001d6e:	1000                	addi	s0,sp,32
    p = allocproc();
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	f24080e7          	jalr	-220(ra) # 80001c94 <allocproc>
    80001d78:	84aa                	mv	s1,a0
    initproc = p;
    80001d7a:	00007797          	auipc	a5,0x7
    80001d7e:	c8a7bf23          	sd	a0,-866(a5) # 80008a18 <initproc>
    uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d82:	03400613          	li	a2,52
    80001d86:	00007597          	auipc	a1,0x7
    80001d8a:	bca58593          	addi	a1,a1,-1078 # 80008950 <initcode>
    80001d8e:	7128                	ld	a0,96(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	5c6080e7          	jalr	1478(ra) # 80001356 <uvmfirst>
    p->sz = PGSIZE;
    80001d98:	6785                	lui	a5,0x1
    80001d9a:	ecbc                	sd	a5,88(s1)
    p->trapframe->epc = 0;     // user program counter
    80001d9c:	74b8                	ld	a4,104(s1)
    80001d9e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
    p->trapframe->sp = PGSIZE; // user stack pointer
    80001da2:	74b8                	ld	a4,104(s1)
    80001da4:	fb1c                	sd	a5,48(a4)
    safestrcpy(p->name, "initcode", sizeof(p->name));
    80001da6:	4641                	li	a2,16
    80001da8:	00006597          	auipc	a1,0x6
    80001dac:	45858593          	addi	a1,a1,1112 # 80008200 <digits+0x1c0>
    80001db0:	16848513          	addi	a0,s1,360
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	068080e7          	jalr	104(ra) # 80000e1c <safestrcpy>
    p->cwd = namei("/");
    80001dbc:	00006517          	auipc	a0,0x6
    80001dc0:	45450513          	addi	a0,a0,1108 # 80008210 <digits+0x1d0>
    80001dc4:	00002097          	auipc	ra,0x2
    80001dc8:	602080e7          	jalr	1538(ra) # 800043c6 <namei>
    80001dcc:	16a4b023          	sd	a0,352(s1)
    p->state = RUNNABLE;
    80001dd0:	478d                	li	a5,3
    80001dd2:	cc9c                	sw	a5,24(s1)
    release(&p->lock);
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	fffff097          	auipc	ra,0xfffff
    80001dda:	eb4080e7          	jalr	-332(ra) # 80000c8a <release>
}
    80001dde:	60e2                	ld	ra,24(sp)
    80001de0:	6442                	ld	s0,16(sp)
    80001de2:	64a2                	ld	s1,8(sp)
    80001de4:	6105                	addi	sp,sp,32
    80001de6:	8082                	ret

0000000080001de8 <growproc>:
{
    80001de8:	1101                	addi	sp,sp,-32
    80001dea:	ec06                	sd	ra,24(sp)
    80001dec:	e822                	sd	s0,16(sp)
    80001dee:	e426                	sd	s1,8(sp)
    80001df0:	e04a                	sd	s2,0(sp)
    80001df2:	1000                	addi	s0,sp,32
    80001df4:	892a                	mv	s2,a0
    struct proc *p = myproc();
    80001df6:	00000097          	auipc	ra,0x0
    80001dfa:	c94080e7          	jalr	-876(ra) # 80001a8a <myproc>
    80001dfe:	84aa                	mv	s1,a0
    sz = p->sz;
    80001e00:	6d2c                	ld	a1,88(a0)
    if (n > 0)
    80001e02:	01204c63          	bgtz	s2,80001e1a <growproc+0x32>
    else if (n < 0)
    80001e06:	02094663          	bltz	s2,80001e32 <growproc+0x4a>
    p->sz = sz;
    80001e0a:	ecac                	sd	a1,88(s1)
    return 0;
    80001e0c:	4501                	li	a0,0
}
    80001e0e:	60e2                	ld	ra,24(sp)
    80001e10:	6442                	ld	s0,16(sp)
    80001e12:	64a2                	ld	s1,8(sp)
    80001e14:	6902                	ld	s2,0(sp)
    80001e16:	6105                	addi	sp,sp,32
    80001e18:	8082                	ret
        if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001e1a:	4691                	li	a3,4
    80001e1c:	00b90633          	add	a2,s2,a1
    80001e20:	7128                	ld	a0,96(a0)
    80001e22:	fffff097          	auipc	ra,0xfffff
    80001e26:	5ee080e7          	jalr	1518(ra) # 80001410 <uvmalloc>
    80001e2a:	85aa                	mv	a1,a0
    80001e2c:	fd79                	bnez	a0,80001e0a <growproc+0x22>
            return -1;
    80001e2e:	557d                	li	a0,-1
    80001e30:	bff9                	j	80001e0e <growproc+0x26>
        sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e32:	00b90633          	add	a2,s2,a1
    80001e36:	7128                	ld	a0,96(a0)
    80001e38:	fffff097          	auipc	ra,0xfffff
    80001e3c:	590080e7          	jalr	1424(ra) # 800013c8 <uvmdealloc>
    80001e40:	85aa                	mv	a1,a0
    80001e42:	b7e1                	j	80001e0a <growproc+0x22>

0000000080001e44 <ps>:
{
    80001e44:	715d                	addi	sp,sp,-80
    80001e46:	e486                	sd	ra,72(sp)
    80001e48:	e0a2                	sd	s0,64(sp)
    80001e4a:	fc26                	sd	s1,56(sp)
    80001e4c:	f84a                	sd	s2,48(sp)
    80001e4e:	f44e                	sd	s3,40(sp)
    80001e50:	f052                	sd	s4,32(sp)
    80001e52:	ec56                	sd	s5,24(sp)
    80001e54:	e85a                	sd	s6,16(sp)
    80001e56:	e45e                	sd	s7,8(sp)
    80001e58:	e062                	sd	s8,0(sp)
    80001e5a:	0880                	addi	s0,sp,80
    80001e5c:	84aa                	mv	s1,a0
    80001e5e:	8bae                	mv	s7,a1
    void *result = (void *)myproc()->sz;
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	c2a080e7          	jalr	-982(ra) # 80001a8a <myproc>
    if (count == 0)
    80001e68:	120b8063          	beqz	s7,80001f88 <ps+0x144>
    void *result = (void *)myproc()->sz;
    80001e6c:	05853b03          	ld	s6,88(a0)
    if (growproc(count * sizeof(struct user_proc)) < 0)
    80001e70:	003b951b          	slliw	a0,s7,0x3
    80001e74:	0175053b          	addw	a0,a0,s7
    80001e78:	0025151b          	slliw	a0,a0,0x2
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	f6c080e7          	jalr	-148(ra) # 80001de8 <growproc>
    80001e84:	10054463          	bltz	a0,80001f8c <ps+0x148>
    struct user_proc loc_result[count];
    80001e88:	003b9a13          	slli	s4,s7,0x3
    80001e8c:	9a5e                	add	s4,s4,s7
    80001e8e:	0a0a                	slli	s4,s4,0x2
    80001e90:	00fa0793          	addi	a5,s4,15
    80001e94:	8391                	srli	a5,a5,0x4
    80001e96:	0792                	slli	a5,a5,0x4
    80001e98:	40f10133          	sub	sp,sp,a5
    80001e9c:	8a8a                	mv	s5,sp
    struct proc *p = proc + (start * sizeof(proc));
    80001e9e:	008a17b7          	lui	a5,0x8a1
    80001ea2:	02f484b3          	mul	s1,s1,a5
    80001ea6:	0000f797          	auipc	a5,0xf
    80001eaa:	21a78793          	addi	a5,a5,538 # 800110c0 <proc>
    80001eae:	94be                	add	s1,s1,a5
    if (p >= &proc[NPROC])
    80001eb0:	00015797          	auipc	a5,0x15
    80001eb4:	01078793          	addi	a5,a5,16 # 80016ec0 <tickslock>
    80001eb8:	0cf4fc63          	bgeu	s1,a5,80001f90 <ps+0x14c>
    80001ebc:	014a8913          	addi	s2,s5,20
    uint8 localCount = 0;
    80001ec0:	4981                	li	s3,0
    for (; p < &proc[NPROC]; p++)
    80001ec2:	8c3e                	mv	s8,a5
    80001ec4:	a069                	j	80001f4e <ps+0x10a>
            loc_result[localCount].state = UNUSED;
    80001ec6:	00399793          	slli	a5,s3,0x3
    80001eca:	97ce                	add	a5,a5,s3
    80001ecc:	078a                	slli	a5,a5,0x2
    80001ece:	97d6                	add	a5,a5,s5
    80001ed0:	0007a023          	sw	zero,0(a5)
            release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	db4080e7          	jalr	-588(ra) # 80000c8a <release>
    if (localCount < count)
    80001ede:	0179f963          	bgeu	s3,s7,80001ef0 <ps+0xac>
        loc_result[localCount].state = UNUSED; // if we reach the end of processes
    80001ee2:	00399793          	slli	a5,s3,0x3
    80001ee6:	97ce                	add	a5,a5,s3
    80001ee8:	078a                	slli	a5,a5,0x2
    80001eea:	97d6                	add	a5,a5,s5
    80001eec:	0007a023          	sw	zero,0(a5)
    void *result = (void *)myproc()->sz;
    80001ef0:	84da                	mv	s1,s6
    copyout(myproc()->pagetable, (uint64)result, (void *)loc_result, count * sizeof(struct user_proc));
    80001ef2:	00000097          	auipc	ra,0x0
    80001ef6:	b98080e7          	jalr	-1128(ra) # 80001a8a <myproc>
    80001efa:	86d2                	mv	a3,s4
    80001efc:	8656                	mv	a2,s5
    80001efe:	85da                	mv	a1,s6
    80001f00:	7128                	ld	a0,96(a0)
    80001f02:	fffff097          	auipc	ra,0xfffff
    80001f06:	76a080e7          	jalr	1898(ra) # 8000166c <copyout>
}
    80001f0a:	8526                	mv	a0,s1
    80001f0c:	fb040113          	addi	sp,s0,-80
    80001f10:	60a6                	ld	ra,72(sp)
    80001f12:	6406                	ld	s0,64(sp)
    80001f14:	74e2                	ld	s1,56(sp)
    80001f16:	7942                	ld	s2,48(sp)
    80001f18:	79a2                	ld	s3,40(sp)
    80001f1a:	7a02                	ld	s4,32(sp)
    80001f1c:	6ae2                	ld	s5,24(sp)
    80001f1e:	6b42                	ld	s6,16(sp)
    80001f20:	6ba2                	ld	s7,8(sp)
    80001f22:	6c02                	ld	s8,0(sp)
    80001f24:	6161                	addi	sp,sp,80
    80001f26:	8082                	ret
            loc_result[localCount].parent_id = p->parent->pid;
    80001f28:	5b9c                	lw	a5,48(a5)
    80001f2a:	fef92e23          	sw	a5,-4(s2)
        release(&p->lock);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	fffff097          	auipc	ra,0xfffff
    80001f34:	d5a080e7          	jalr	-678(ra) # 80000c8a <release>
        localCount++;
    80001f38:	2985                	addiw	s3,s3,1
    80001f3a:	0ff9f993          	zext.b	s3,s3
    for (; p < &proc[NPROC]; p++)
    80001f3e:	17848493          	addi	s1,s1,376
    80001f42:	f984fee3          	bgeu	s1,s8,80001ede <ps+0x9a>
        if (localCount == count)
    80001f46:	02490913          	addi	s2,s2,36
    80001f4a:	fb3b83e3          	beq	s7,s3,80001ef0 <ps+0xac>
        acquire(&p->lock);
    80001f4e:	8526                	mv	a0,s1
    80001f50:	fffff097          	auipc	ra,0xfffff
    80001f54:	c86080e7          	jalr	-890(ra) # 80000bd6 <acquire>
        if (p->state == UNUSED)
    80001f58:	4c9c                	lw	a5,24(s1)
    80001f5a:	d7b5                	beqz	a5,80001ec6 <ps+0x82>
        loc_result[localCount].state = p->state;
    80001f5c:	fef92623          	sw	a5,-20(s2)
        loc_result[localCount].killed = p->killed;
    80001f60:	549c                	lw	a5,40(s1)
    80001f62:	fef92823          	sw	a5,-16(s2)
        loc_result[localCount].xstate = p->xstate;
    80001f66:	54dc                	lw	a5,44(s1)
    80001f68:	fef92a23          	sw	a5,-12(s2)
        loc_result[localCount].pid = p->pid;
    80001f6c:	589c                	lw	a5,48(s1)
    80001f6e:	fef92c23          	sw	a5,-8(s2)
        copy_array(p->name, loc_result[localCount].name, 16);
    80001f72:	4641                	li	a2,16
    80001f74:	85ca                	mv	a1,s2
    80001f76:	16848513          	addi	a0,s1,360
    80001f7a:	00000097          	auipc	ra,0x0
    80001f7e:	ab6080e7          	jalr	-1354(ra) # 80001a30 <copy_array>
        if (p->parent != 0) // init
    80001f82:	64bc                	ld	a5,72(s1)
    80001f84:	f3d5                	bnez	a5,80001f28 <ps+0xe4>
    80001f86:	b765                	j	80001f2e <ps+0xea>
        return result;
    80001f88:	4481                	li	s1,0
    80001f8a:	b741                	j	80001f0a <ps+0xc6>
        return result;
    80001f8c:	4481                	li	s1,0
    80001f8e:	bfb5                	j	80001f0a <ps+0xc6>
        return result;
    80001f90:	4481                	li	s1,0
    80001f92:	bfa5                	j	80001f0a <ps+0xc6>

0000000080001f94 <fork>:
{
    80001f94:	7139                	addi	sp,sp,-64
    80001f96:	fc06                	sd	ra,56(sp)
    80001f98:	f822                	sd	s0,48(sp)
    80001f9a:	f426                	sd	s1,40(sp)
    80001f9c:	f04a                	sd	s2,32(sp)
    80001f9e:	ec4e                	sd	s3,24(sp)
    80001fa0:	e852                	sd	s4,16(sp)
    80001fa2:	e456                	sd	s5,8(sp)
    80001fa4:	0080                	addi	s0,sp,64
    struct proc *p = myproc();
    80001fa6:	00000097          	auipc	ra,0x0
    80001faa:	ae4080e7          	jalr	-1308(ra) # 80001a8a <myproc>
    80001fae:	8aaa                	mv	s5,a0
    if ((np = allocproc()) == 0)
    80001fb0:	00000097          	auipc	ra,0x0
    80001fb4:	ce4080e7          	jalr	-796(ra) # 80001c94 <allocproc>
    80001fb8:	10050c63          	beqz	a0,800020d0 <fork+0x13c>
    80001fbc:	8a2a                	mv	s4,a0
    if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001fbe:	058ab603          	ld	a2,88(s5)
    80001fc2:	712c                	ld	a1,96(a0)
    80001fc4:	060ab503          	ld	a0,96(s5)
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	5a0080e7          	jalr	1440(ra) # 80001568 <uvmcopy>
    80001fd0:	04054863          	bltz	a0,80002020 <fork+0x8c>
    np->sz = p->sz;
    80001fd4:	058ab783          	ld	a5,88(s5)
    80001fd8:	04fa3c23          	sd	a5,88(s4)
    *(np->trapframe) = *(p->trapframe);
    80001fdc:	068ab683          	ld	a3,104(s5)
    80001fe0:	87b6                	mv	a5,a3
    80001fe2:	068a3703          	ld	a4,104(s4)
    80001fe6:	12068693          	addi	a3,a3,288
    80001fea:	0007b803          	ld	a6,0(a5)
    80001fee:	6788                	ld	a0,8(a5)
    80001ff0:	6b8c                	ld	a1,16(a5)
    80001ff2:	6f90                	ld	a2,24(a5)
    80001ff4:	01073023          	sd	a6,0(a4)
    80001ff8:	e708                	sd	a0,8(a4)
    80001ffa:	eb0c                	sd	a1,16(a4)
    80001ffc:	ef10                	sd	a2,24(a4)
    80001ffe:	02078793          	addi	a5,a5,32
    80002002:	02070713          	addi	a4,a4,32
    80002006:	fed792e3          	bne	a5,a3,80001fea <fork+0x56>
    np->trapframe->a0 = 0;
    8000200a:	068a3783          	ld	a5,104(s4)
    8000200e:	0607b823          	sd	zero,112(a5)
    for (i = 0; i < NOFILE; i++)
    80002012:	0e0a8493          	addi	s1,s5,224
    80002016:	0e0a0913          	addi	s2,s4,224
    8000201a:	160a8993          	addi	s3,s5,352
    8000201e:	a00d                	j	80002040 <fork+0xac>
        freeproc(np);
    80002020:	8552                	mv	a0,s4
    80002022:	00000097          	auipc	ra,0x0
    80002026:	c1a080e7          	jalr	-998(ra) # 80001c3c <freeproc>
        release(&np->lock);
    8000202a:	8552                	mv	a0,s4
    8000202c:	fffff097          	auipc	ra,0xfffff
    80002030:	c5e080e7          	jalr	-930(ra) # 80000c8a <release>
        return -1;
    80002034:	597d                	li	s2,-1
    80002036:	a059                	j	800020bc <fork+0x128>
    for (i = 0; i < NOFILE; i++)
    80002038:	04a1                	addi	s1,s1,8
    8000203a:	0921                	addi	s2,s2,8
    8000203c:	01348b63          	beq	s1,s3,80002052 <fork+0xbe>
        if (p->ofile[i])
    80002040:	6088                	ld	a0,0(s1)
    80002042:	d97d                	beqz	a0,80002038 <fork+0xa4>
            np->ofile[i] = filedup(p->ofile[i]);
    80002044:	00003097          	auipc	ra,0x3
    80002048:	a18080e7          	jalr	-1512(ra) # 80004a5c <filedup>
    8000204c:	00a93023          	sd	a0,0(s2)
    80002050:	b7e5                	j	80002038 <fork+0xa4>
    np->cwd = idup(p->cwd);
    80002052:	160ab503          	ld	a0,352(s5)
    80002056:	00002097          	auipc	ra,0x2
    8000205a:	b86080e7          	jalr	-1146(ra) # 80003bdc <idup>
    8000205e:	16aa3023          	sd	a0,352(s4)
    safestrcpy(np->name, p->name, sizeof(p->name));
    80002062:	4641                	li	a2,16
    80002064:	168a8593          	addi	a1,s5,360
    80002068:	168a0513          	addi	a0,s4,360
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	db0080e7          	jalr	-592(ra) # 80000e1c <safestrcpy>
    pid = np->pid;
    80002074:	030a2903          	lw	s2,48(s4)
    release(&np->lock);
    80002078:	8552                	mv	a0,s4
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	c10080e7          	jalr	-1008(ra) # 80000c8a <release>
    acquire(&wait_lock);
    80002082:	0000f497          	auipc	s1,0xf
    80002086:	02648493          	addi	s1,s1,38 # 800110a8 <wait_lock>
    8000208a:	8526                	mv	a0,s1
    8000208c:	fffff097          	auipc	ra,0xfffff
    80002090:	b4a080e7          	jalr	-1206(ra) # 80000bd6 <acquire>
    np->parent = p;
    80002094:	055a3423          	sd	s5,72(s4)
    release(&wait_lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	bf0080e7          	jalr	-1040(ra) # 80000c8a <release>
    acquire(&np->lock);
    800020a2:	8552                	mv	a0,s4
    800020a4:	fffff097          	auipc	ra,0xfffff
    800020a8:	b32080e7          	jalr	-1230(ra) # 80000bd6 <acquire>
    np->state = RUNNABLE;
    800020ac:	478d                	li	a5,3
    800020ae:	00fa2c23          	sw	a5,24(s4)
    release(&np->lock);
    800020b2:	8552                	mv	a0,s4
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	bd6080e7          	jalr	-1066(ra) # 80000c8a <release>
}
    800020bc:	854a                	mv	a0,s2
    800020be:	70e2                	ld	ra,56(sp)
    800020c0:	7442                	ld	s0,48(sp)
    800020c2:	74a2                	ld	s1,40(sp)
    800020c4:	7902                	ld	s2,32(sp)
    800020c6:	69e2                	ld	s3,24(sp)
    800020c8:	6a42                	ld	s4,16(sp)
    800020ca:	6aa2                	ld	s5,8(sp)
    800020cc:	6121                	addi	sp,sp,64
    800020ce:	8082                	ret
        return -1;
    800020d0:	597d                	li	s2,-1
    800020d2:	b7ed                	j	800020bc <fork+0x128>

00000000800020d4 <scheduler>:
{
    800020d4:	1101                	addi	sp,sp,-32
    800020d6:	ec06                	sd	ra,24(sp)
    800020d8:	e822                	sd	s0,16(sp)
    800020da:	e426                	sd	s1,8(sp)
    800020dc:	1000                	addi	s0,sp,32
        (*sched_pointer)();
    800020de:	00007497          	auipc	s1,0x7
    800020e2:	85a48493          	addi	s1,s1,-1958 # 80008938 <sched_pointer>
    800020e6:	609c                	ld	a5,0(s1)
    800020e8:	9782                	jalr	a5
    while (1)
    800020ea:	bff5                	j	800020e6 <scheduler+0x12>

00000000800020ec <enqueue>:
{
    800020ec:	1141                	addi	sp,sp,-16
    800020ee:	e422                	sd	s0,8(sp)
    800020f0:	0800                	addi	s0,sp,16
    if (q->tail != 0)
    800020f2:	651c                	ld	a5,8(a0)
    800020f4:	cb91                	beqz	a5,80002108 <enqueue+0x1c>
        q->tail->next = p;
    800020f6:	e3ac                	sd	a1,64(a5)
        p->prev = q->tail;
    800020f8:	651c                	ld	a5,8(a0)
    800020fa:	fd9c                	sd	a5,56(a1)
        p->next = 0;
    800020fc:	0405b023          	sd	zero,64(a1)
        q->tail = p;
    80002100:	e50c                	sd	a1,8(a0)
}
    80002102:	6422                	ld	s0,8(sp)
    80002104:	0141                	addi	sp,sp,16
    80002106:	8082                	ret
        q->head = p;
    80002108:	e10c                	sd	a1,0(a0)
        q->tail = p;
    8000210a:	e50c                	sd	a1,8(a0)
        p->prev = 0;
    8000210c:	0205bc23          	sd	zero,56(a1)
        p->next = 0;
    80002110:	0405b023          	sd	zero,64(a1)
}
    80002114:	b7fd                	j	80002102 <enqueue+0x16>

0000000080002116 <dequeue>:
{
    80002116:	1141                	addi	sp,sp,-16
    80002118:	e422                	sd	s0,8(sp)
    8000211a:	0800                	addi	s0,sp,16
    8000211c:	87aa                	mv	a5,a0
    struct proc *p = q->head;
    8000211e:	6108                	ld	a0,0(a0)
    if (p != 0)
    80002120:	c911                	beqz	a0,80002134 <dequeue+0x1e>
        q->head = p->next;
    80002122:	6138                	ld	a4,64(a0)
    80002124:	e398                	sd	a4,0(a5)
        if (q->head != 0)
    80002126:	cb11                	beqz	a4,8000213a <dequeue+0x24>
            q->head->prev = 0;
    80002128:	02073c23          	sd	zero,56(a4)
        p->prev = 0;
    8000212c:	02053c23          	sd	zero,56(a0)
        p->next = 0;
    80002130:	04053023          	sd	zero,64(a0)
}
    80002134:	6422                	ld	s0,8(sp)
    80002136:	0141                	addi	sp,sp,16
    80002138:	8082                	ret
            q->tail = 0;
    8000213a:	0007b423          	sd	zero,8(a5)
    8000213e:	b7fd                	j	8000212c <dequeue+0x16>

0000000080002140 <mlfq_scheduler>:
{
    80002140:	711d                	addi	sp,sp,-96
    80002142:	ec86                	sd	ra,88(sp)
    80002144:	e8a2                	sd	s0,80(sp)
    80002146:	e4a6                	sd	s1,72(sp)
    80002148:	e0ca                	sd	s2,64(sp)
    8000214a:	fc4e                	sd	s3,56(sp)
    8000214c:	f852                	sd	s4,48(sp)
    8000214e:	f456                	sd	s5,40(sp)
    80002150:	f05a                	sd	s6,32(sp)
    80002152:	ec5e                	sd	s7,24(sp)
    80002154:	e862                	sd	s8,16(sp)
    80002156:	e466                	sd	s9,8(sp)
    80002158:	1080                	addi	s0,sp,96
    struct queue *q0 = (struct queue *)kalloc(); // First queue (higher priority)
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	98c080e7          	jalr	-1652(ra) # 80000ae6 <kalloc>
    80002162:	892a                	mv	s2,a0
    struct queue *q1 = (struct queue *)kalloc(); // Second queue (lower priority)
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	982080e7          	jalr	-1662(ra) # 80000ae6 <kalloc>
    8000216c:	8a2a                	mv	s4,a0
    struct queue *q2 = (struct queue *)kalloc(); // Third queue (lowest priority)
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	978080e7          	jalr	-1672(ra) # 80000ae6 <kalloc>
    80002176:	8aaa                	mv	s5,a0
    q0->head = 0;
    80002178:	00093023          	sd	zero,0(s2)
    q0->tail = 0;
    8000217c:	00093423          	sd	zero,8(s2)
    q1->head = 0;
    80002180:	000a3023          	sd	zero,0(s4)
    q1->tail = 0;
    80002184:	000a3423          	sd	zero,8(s4)
    q2->head = 0;
    80002188:	00053023          	sd	zero,0(a0)
    q2->tail = 0;
    8000218c:	00053423          	sd	zero,8(a0)
    80002190:	8b12                	mv	s6,tp
    int id = r_tp();
    80002192:	2b01                	sext.w	s6,s6
    c->proc = 0;
    80002194:	007b1713          	slli	a4,s6,0x7
    80002198:	0000f797          	auipc	a5,0xf
    8000219c:	af878793          	addi	a5,a5,-1288 # 80010c90 <cpus>
    800021a0:	97ba                	add	a5,a5,a4
    800021a2:	0007b023          	sd	zero,0(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021a6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800021aa:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800021ae:	10079073          	csrw	sstatus,a5
    for (p0 = proc; p0 < &proc[NPROC]; p0++)
    800021b2:	0000f497          	auipc	s1,0xf
    800021b6:	f0e48493          	addi	s1,s1,-242 # 800110c0 <proc>
    800021ba:	00015997          	auipc	s3,0x15
    800021be:	d0698993          	addi	s3,s3,-762 # 80016ec0 <tickslock>
        enqueue(q0, p0);
    800021c2:	85a6                	mv	a1,s1
    800021c4:	854a                	mv	a0,s2
    800021c6:	00000097          	auipc	ra,0x0
    800021ca:	f26080e7          	jalr	-218(ra) # 800020ec <enqueue>
    for (p0 = proc; p0 < &proc[NPROC]; p0++)
    800021ce:	17848493          	addi	s1,s1,376
    800021d2:	ff3498e3          	bne	s1,s3,800021c2 <mlfq_scheduler+0x82>
    while (q0->head != 0)
    800021d6:	00093783          	ld	a5,0(s2)
    800021da:	14078663          	beqz	a5,80002326 <mlfq_scheduler+0x1e6>
            swtch(&c->context, &p1->context);
    800021de:	007b1b93          	slli	s7,s6,0x7
    800021e2:	0000f797          	auipc	a5,0xf
    800021e6:	ab678793          	addi	a5,a5,-1354 # 80010c98 <cpus+0x8>
    800021ea:	9bbe                	add	s7,s7,a5
        if (p1->state == RUNNABLE)
    800021ec:	498d                	li	s3,3
            p1->state = RUNNING;
    800021ee:	4c91                	li	s9,4
            c->proc = p1;
    800021f0:	007b1793          	slli	a5,s6,0x7
    800021f4:	0000fc17          	auipc	s8,0xf
    800021f8:	a9cc0c13          	addi	s8,s8,-1380 # 80010c90 <cpus>
    800021fc:	9c3e                	add	s8,s8,a5
    800021fe:	a811                	j	80002212 <mlfq_scheduler+0xd2>
        release(&p1->lock);
    80002200:	8526                	mv	a0,s1
    80002202:	fffff097          	auipc	ra,0xfffff
    80002206:	a88080e7          	jalr	-1400(ra) # 80000c8a <release>
    while (q0->head != 0)
    8000220a:	00093783          	ld	a5,0(s2)
    8000220e:	10078c63          	beqz	a5,80002326 <mlfq_scheduler+0x1e6>
        p1 = dequeue(q0);
    80002212:	854a                	mv	a0,s2
    80002214:	00000097          	auipc	ra,0x0
    80002218:	f02080e7          	jalr	-254(ra) # 80002116 <dequeue>
    8000221c:	84aa                	mv	s1,a0
        acquire(&p1->lock);
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	9b8080e7          	jalr	-1608(ra) # 80000bd6 <acquire>
        enqueue(q1, p1);
    80002226:	85a6                	mv	a1,s1
    80002228:	8552                	mv	a0,s4
    8000222a:	00000097          	auipc	ra,0x0
    8000222e:	ec2080e7          	jalr	-318(ra) # 800020ec <enqueue>
        if (p1->state == RUNNABLE)
    80002232:	4c9c                	lw	a5,24(s1)
    80002234:	fd3796e3          	bne	a5,s3,80002200 <mlfq_scheduler+0xc0>
            p1->state = RUNNING;
    80002238:	0194ac23          	sw	s9,24(s1)
            c->proc = p1;
    8000223c:	009c3023          	sd	s1,0(s8)
            swtch(&c->context, &p1->context);
    80002240:	07048593          	addi	a1,s1,112
    80002244:	855e                	mv	a0,s7
    80002246:	00001097          	auipc	ra,0x1
    8000224a:	8d0080e7          	jalr	-1840(ra) # 80002b16 <swtch>
            c->proc = 0;
    8000224e:	000c3023          	sd	zero,0(s8)
    80002252:	b77d                	j	80002200 <mlfq_scheduler+0xc0>
        release(&p1->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	a34080e7          	jalr	-1484(ra) # 80000c8a <release>
    while ((q0->head == 0) && (q1->head != 0))
    8000225e:	00093783          	ld	a5,0(s2)
    80002262:	e3fd                	bnez	a5,80002348 <mlfq_scheduler+0x208>
    80002264:	000a3783          	ld	a5,0(s4)
    80002268:	c3b1                	beqz	a5,800022ac <mlfq_scheduler+0x16c>
        p1 = dequeue(q1);
    8000226a:	8552                	mv	a0,s4
    8000226c:	00000097          	auipc	ra,0x0
    80002270:	eaa080e7          	jalr	-342(ra) # 80002116 <dequeue>
    80002274:	84aa                	mv	s1,a0
        acquire(&p1->lock);
    80002276:	fffff097          	auipc	ra,0xfffff
    8000227a:	960080e7          	jalr	-1696(ra) # 80000bd6 <acquire>
        enqueue(q2, p1);
    8000227e:	85a6                	mv	a1,s1
    80002280:	8556                	mv	a0,s5
    80002282:	00000097          	auipc	ra,0x0
    80002286:	e6a080e7          	jalr	-406(ra) # 800020ec <enqueue>
        if (p1->state == RUNNABLE)
    8000228a:	4c9c                	lw	a5,24(s1)
    8000228c:	fd7794e3          	bne	a5,s7,80002254 <mlfq_scheduler+0x114>
            p1->state = RUNNING;
    80002290:	0194ac23          	sw	s9,24(s1)
            c->proc = p1;
    80002294:	009c3023          	sd	s1,0(s8)
            swtch(&c->context, &p1->context);
    80002298:	07048593          	addi	a1,s1,112
    8000229c:	854e                	mv	a0,s3
    8000229e:	00001097          	auipc	ra,0x1
    800022a2:	878080e7          	jalr	-1928(ra) # 80002b16 <swtch>
            c->proc = 0;
    800022a6:	000c3023          	sd	zero,0(s8)
    800022aa:	b76d                	j	80002254 <mlfq_scheduler+0x114>
    while ((q0->head == 0) && (q1->head == 0) && (q2->head != 0))
    800022ac:	00093783          	ld	a5,0(s2)
    800022b0:	efc1                	bnez	a5,80002348 <mlfq_scheduler+0x208>
        if (p1->state == RUNNABLE)
    800022b2:	4b8d                	li	s7,3
            p1->state = RUNNING;
    800022b4:	4c11                	li	s8,4
            c->proc = p1;
    800022b6:	007b1793          	slli	a5,s6,0x7
    800022ba:	0000fb17          	auipc	s6,0xf
    800022be:	9d6b0b13          	addi	s6,s6,-1578 # 80010c90 <cpus>
    800022c2:	9b3e                	add	s6,s6,a5
    800022c4:	a809                	j	800022d6 <mlfq_scheduler+0x196>
        release(&p1->lock);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	9c2080e7          	jalr	-1598(ra) # 80000c8a <release>
    while ((q0->head == 0) && (q1->head == 0) && (q2->head != 0))
    800022d0:	00093783          	ld	a5,0(s2)
    800022d4:	ebb5                	bnez	a5,80002348 <mlfq_scheduler+0x208>
    800022d6:	000a3783          	ld	a5,0(s4)
    800022da:	e7bd                	bnez	a5,80002348 <mlfq_scheduler+0x208>
    800022dc:	000ab783          	ld	a5,0(s5)
    800022e0:	c7a5                	beqz	a5,80002348 <mlfq_scheduler+0x208>
        p1 = dequeue(q2);
    800022e2:	8556                	mv	a0,s5
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	e32080e7          	jalr	-462(ra) # 80002116 <dequeue>
    800022ec:	84aa                	mv	s1,a0
        enqueue(q0, p1);
    800022ee:	85aa                	mv	a1,a0
    800022f0:	854a                	mv	a0,s2
    800022f2:	00000097          	auipc	ra,0x0
    800022f6:	dfa080e7          	jalr	-518(ra) # 800020ec <enqueue>
        acquire(&p1->lock);
    800022fa:	8526                	mv	a0,s1
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	8da080e7          	jalr	-1830(ra) # 80000bd6 <acquire>
        if (p1->state == RUNNABLE)
    80002304:	4c9c                	lw	a5,24(s1)
    80002306:	fd7790e3          	bne	a5,s7,800022c6 <mlfq_scheduler+0x186>
            p1->state = RUNNING;
    8000230a:	0184ac23          	sw	s8,24(s1)
            c->proc = p1;
    8000230e:	009b3023          	sd	s1,0(s6)
            swtch(&c->context, &p1->context);
    80002312:	07048593          	addi	a1,s1,112
    80002316:	854e                	mv	a0,s3
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	7fe080e7          	jalr	2046(ra) # 80002b16 <swtch>
            c->proc = 0;
    80002320:	000b3023          	sd	zero,0(s6)
    80002324:	b74d                	j	800022c6 <mlfq_scheduler+0x186>
            swtch(&c->context, &p1->context);
    80002326:	007b1993          	slli	s3,s6,0x7
    8000232a:	0000f797          	auipc	a5,0xf
    8000232e:	96e78793          	addi	a5,a5,-1682 # 80010c98 <cpus+0x8>
    80002332:	99be                	add	s3,s3,a5
        if (p1->state == RUNNABLE)
    80002334:	4b8d                	li	s7,3
            p1->state = RUNNING;
    80002336:	4c91                	li	s9,4
            c->proc = p1;
    80002338:	007b1793          	slli	a5,s6,0x7
    8000233c:	0000fc17          	auipc	s8,0xf
    80002340:	954c0c13          	addi	s8,s8,-1708 # 80010c90 <cpus>
    80002344:	9c3e                	add	s8,s8,a5
    80002346:	bf39                	j	80002264 <mlfq_scheduler+0x124>
}
    80002348:	60e6                	ld	ra,88(sp)
    8000234a:	6446                	ld	s0,80(sp)
    8000234c:	64a6                	ld	s1,72(sp)
    8000234e:	6906                	ld	s2,64(sp)
    80002350:	79e2                	ld	s3,56(sp)
    80002352:	7a42                	ld	s4,48(sp)
    80002354:	7aa2                	ld	s5,40(sp)
    80002356:	7b02                	ld	s6,32(sp)
    80002358:	6be2                	ld	s7,24(sp)
    8000235a:	6c42                	ld	s8,16(sp)
    8000235c:	6ca2                	ld	s9,8(sp)
    8000235e:	6125                	addi	sp,sp,96
    80002360:	8082                	ret

0000000080002362 <sched>:
{
    80002362:	7179                	addi	sp,sp,-48
    80002364:	f406                	sd	ra,40(sp)
    80002366:	f022                	sd	s0,32(sp)
    80002368:	ec26                	sd	s1,24(sp)
    8000236a:	e84a                	sd	s2,16(sp)
    8000236c:	e44e                	sd	s3,8(sp)
    8000236e:	1800                	addi	s0,sp,48
    struct proc *p = myproc();
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	71a080e7          	jalr	1818(ra) # 80001a8a <myproc>
    80002378:	84aa                	mv	s1,a0
    if (!holding(&p->lock))
    8000237a:	ffffe097          	auipc	ra,0xffffe
    8000237e:	7e2080e7          	jalr	2018(ra) # 80000b5c <holding>
    80002382:	c53d                	beqz	a0,800023f0 <sched+0x8e>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002384:	8792                	mv	a5,tp
    if (mycpu()->noff != 1)
    80002386:	2781                	sext.w	a5,a5
    80002388:	079e                	slli	a5,a5,0x7
    8000238a:	0000f717          	auipc	a4,0xf
    8000238e:	90670713          	addi	a4,a4,-1786 # 80010c90 <cpus>
    80002392:	97ba                	add	a5,a5,a4
    80002394:	5fb8                	lw	a4,120(a5)
    80002396:	4785                	li	a5,1
    80002398:	06f71463          	bne	a4,a5,80002400 <sched+0x9e>
    if (p->state == RUNNING)
    8000239c:	4c98                	lw	a4,24(s1)
    8000239e:	4791                	li	a5,4
    800023a0:	06f70863          	beq	a4,a5,80002410 <sched+0xae>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023a4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023a8:	8b89                	andi	a5,a5,2
    if (intr_get())
    800023aa:	ebbd                	bnez	a5,80002420 <sched+0xbe>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023ac:	8792                	mv	a5,tp
    intena = mycpu()->intena;
    800023ae:	0000f917          	auipc	s2,0xf
    800023b2:	8e290913          	addi	s2,s2,-1822 # 80010c90 <cpus>
    800023b6:	2781                	sext.w	a5,a5
    800023b8:	079e                	slli	a5,a5,0x7
    800023ba:	97ca                	add	a5,a5,s2
    800023bc:	07c7a983          	lw	s3,124(a5)
    800023c0:	8592                	mv	a1,tp
    swtch(&p->context, &mycpu()->context);
    800023c2:	2581                	sext.w	a1,a1
    800023c4:	059e                	slli	a1,a1,0x7
    800023c6:	05a1                	addi	a1,a1,8
    800023c8:	95ca                	add	a1,a1,s2
    800023ca:	07048513          	addi	a0,s1,112
    800023ce:	00000097          	auipc	ra,0x0
    800023d2:	748080e7          	jalr	1864(ra) # 80002b16 <swtch>
    800023d6:	8792                	mv	a5,tp
    mycpu()->intena = intena;
    800023d8:	2781                	sext.w	a5,a5
    800023da:	079e                	slli	a5,a5,0x7
    800023dc:	993e                	add	s2,s2,a5
    800023de:	07392e23          	sw	s3,124(s2)
}
    800023e2:	70a2                	ld	ra,40(sp)
    800023e4:	7402                	ld	s0,32(sp)
    800023e6:	64e2                	ld	s1,24(sp)
    800023e8:	6942                	ld	s2,16(sp)
    800023ea:	69a2                	ld	s3,8(sp)
    800023ec:	6145                	addi	sp,sp,48
    800023ee:	8082                	ret
        panic("sched p->lock");
    800023f0:	00006517          	auipc	a0,0x6
    800023f4:	e2850513          	addi	a0,a0,-472 # 80008218 <digits+0x1d8>
    800023f8:	ffffe097          	auipc	ra,0xffffe
    800023fc:	148080e7          	jalr	328(ra) # 80000540 <panic>
        panic("sched locks");
    80002400:	00006517          	auipc	a0,0x6
    80002404:	e2850513          	addi	a0,a0,-472 # 80008228 <digits+0x1e8>
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	138080e7          	jalr	312(ra) # 80000540 <panic>
        panic("sched running");
    80002410:	00006517          	auipc	a0,0x6
    80002414:	e2850513          	addi	a0,a0,-472 # 80008238 <digits+0x1f8>
    80002418:	ffffe097          	auipc	ra,0xffffe
    8000241c:	128080e7          	jalr	296(ra) # 80000540 <panic>
        panic("sched interruptible");
    80002420:	00006517          	auipc	a0,0x6
    80002424:	e2850513          	addi	a0,a0,-472 # 80008248 <digits+0x208>
    80002428:	ffffe097          	auipc	ra,0xffffe
    8000242c:	118080e7          	jalr	280(ra) # 80000540 <panic>

0000000080002430 <yield>:
{
    80002430:	1101                	addi	sp,sp,-32
    80002432:	ec06                	sd	ra,24(sp)
    80002434:	e822                	sd	s0,16(sp)
    80002436:	e426                	sd	s1,8(sp)
    80002438:	1000                	addi	s0,sp,32
    struct proc *p = myproc();
    8000243a:	fffff097          	auipc	ra,0xfffff
    8000243e:	650080e7          	jalr	1616(ra) # 80001a8a <myproc>
    80002442:	84aa                	mv	s1,a0
    acquire(&p->lock);
    80002444:	ffffe097          	auipc	ra,0xffffe
    80002448:	792080e7          	jalr	1938(ra) # 80000bd6 <acquire>
    p->state = RUNNABLE;
    8000244c:	478d                	li	a5,3
    8000244e:	cc9c                	sw	a5,24(s1)
    sched();
    80002450:	00000097          	auipc	ra,0x0
    80002454:	f12080e7          	jalr	-238(ra) # 80002362 <sched>
    release(&p->lock);
    80002458:	8526                	mv	a0,s1
    8000245a:	fffff097          	auipc	ra,0xfffff
    8000245e:	830080e7          	jalr	-2000(ra) # 80000c8a <release>
}
    80002462:	60e2                	ld	ra,24(sp)
    80002464:	6442                	ld	s0,16(sp)
    80002466:	64a2                	ld	s1,8(sp)
    80002468:	6105                	addi	sp,sp,32
    8000246a:	8082                	ret

000000008000246c <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000246c:	7179                	addi	sp,sp,-48
    8000246e:	f406                	sd	ra,40(sp)
    80002470:	f022                	sd	s0,32(sp)
    80002472:	ec26                	sd	s1,24(sp)
    80002474:	e84a                	sd	s2,16(sp)
    80002476:	e44e                	sd	s3,8(sp)
    80002478:	1800                	addi	s0,sp,48
    8000247a:	89aa                	mv	s3,a0
    8000247c:	892e                	mv	s2,a1
    struct proc *p = myproc();
    8000247e:	fffff097          	auipc	ra,0xfffff
    80002482:	60c080e7          	jalr	1548(ra) # 80001a8a <myproc>
    80002486:	84aa                	mv	s1,a0
    // Once we hold p->lock, we can be
    // guaranteed that we won't miss any wakeup
    // (wakeup locks p->lock),
    // so it's okay to release lk.

    acquire(&p->lock); // DOC: sleeplock1
    80002488:	ffffe097          	auipc	ra,0xffffe
    8000248c:	74e080e7          	jalr	1870(ra) # 80000bd6 <acquire>
    release(lk);
    80002490:	854a                	mv	a0,s2
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	7f8080e7          	jalr	2040(ra) # 80000c8a <release>

    // Go to sleep.
    p->chan = chan;
    8000249a:	0334b023          	sd	s3,32(s1)
    p->state = SLEEPING;
    8000249e:	4789                	li	a5,2
    800024a0:	cc9c                	sw	a5,24(s1)

    sched();
    800024a2:	00000097          	auipc	ra,0x0
    800024a6:	ec0080e7          	jalr	-320(ra) # 80002362 <sched>

    // Tidy up.
    p->chan = 0;
    800024aa:	0204b023          	sd	zero,32(s1)

    // Reacquire original lock.
    release(&p->lock);
    800024ae:	8526                	mv	a0,s1
    800024b0:	ffffe097          	auipc	ra,0xffffe
    800024b4:	7da080e7          	jalr	2010(ra) # 80000c8a <release>
    acquire(lk);
    800024b8:	854a                	mv	a0,s2
    800024ba:	ffffe097          	auipc	ra,0xffffe
    800024be:	71c080e7          	jalr	1820(ra) # 80000bd6 <acquire>
}
    800024c2:	70a2                	ld	ra,40(sp)
    800024c4:	7402                	ld	s0,32(sp)
    800024c6:	64e2                	ld	s1,24(sp)
    800024c8:	6942                	ld	s2,16(sp)
    800024ca:	69a2                	ld	s3,8(sp)
    800024cc:	6145                	addi	sp,sp,48
    800024ce:	8082                	ret

00000000800024d0 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800024d0:	7139                	addi	sp,sp,-64
    800024d2:	fc06                	sd	ra,56(sp)
    800024d4:	f822                	sd	s0,48(sp)
    800024d6:	f426                	sd	s1,40(sp)
    800024d8:	f04a                	sd	s2,32(sp)
    800024da:	ec4e                	sd	s3,24(sp)
    800024dc:	e852                	sd	s4,16(sp)
    800024de:	e456                	sd	s5,8(sp)
    800024e0:	0080                	addi	s0,sp,64
    800024e2:	8a2a                	mv	s4,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    800024e4:	0000f497          	auipc	s1,0xf
    800024e8:	bdc48493          	addi	s1,s1,-1060 # 800110c0 <proc>
    {
        if (p != myproc())
        {
            acquire(&p->lock);
            if (p->state == SLEEPING && p->chan == chan)
    800024ec:	4989                	li	s3,2
            {
                p->state = RUNNABLE;
    800024ee:	4a8d                	li	s5,3
    for (p = proc; p < &proc[NPROC]; p++)
    800024f0:	00015917          	auipc	s2,0x15
    800024f4:	9d090913          	addi	s2,s2,-1584 # 80016ec0 <tickslock>
    800024f8:	a811                	j	8000250c <wakeup+0x3c>
            }
            release(&p->lock);
    800024fa:	8526                	mv	a0,s1
    800024fc:	ffffe097          	auipc	ra,0xffffe
    80002500:	78e080e7          	jalr	1934(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002504:	17848493          	addi	s1,s1,376
    80002508:	03248663          	beq	s1,s2,80002534 <wakeup+0x64>
        if (p != myproc())
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	57e080e7          	jalr	1406(ra) # 80001a8a <myproc>
    80002514:	fea488e3          	beq	s1,a0,80002504 <wakeup+0x34>
            acquire(&p->lock);
    80002518:	8526                	mv	a0,s1
    8000251a:	ffffe097          	auipc	ra,0xffffe
    8000251e:	6bc080e7          	jalr	1724(ra) # 80000bd6 <acquire>
            if (p->state == SLEEPING && p->chan == chan)
    80002522:	4c9c                	lw	a5,24(s1)
    80002524:	fd379be3          	bne	a5,s3,800024fa <wakeup+0x2a>
    80002528:	709c                	ld	a5,32(s1)
    8000252a:	fd4798e3          	bne	a5,s4,800024fa <wakeup+0x2a>
                p->state = RUNNABLE;
    8000252e:	0154ac23          	sw	s5,24(s1)
    80002532:	b7e1                	j	800024fa <wakeup+0x2a>
        }
    }
}
    80002534:	70e2                	ld	ra,56(sp)
    80002536:	7442                	ld	s0,48(sp)
    80002538:	74a2                	ld	s1,40(sp)
    8000253a:	7902                	ld	s2,32(sp)
    8000253c:	69e2                	ld	s3,24(sp)
    8000253e:	6a42                	ld	s4,16(sp)
    80002540:	6aa2                	ld	s5,8(sp)
    80002542:	6121                	addi	sp,sp,64
    80002544:	8082                	ret

0000000080002546 <reparent>:
{
    80002546:	7179                	addi	sp,sp,-48
    80002548:	f406                	sd	ra,40(sp)
    8000254a:	f022                	sd	s0,32(sp)
    8000254c:	ec26                	sd	s1,24(sp)
    8000254e:	e84a                	sd	s2,16(sp)
    80002550:	e44e                	sd	s3,8(sp)
    80002552:	e052                	sd	s4,0(sp)
    80002554:	1800                	addi	s0,sp,48
    80002556:	892a                	mv	s2,a0
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002558:	0000f497          	auipc	s1,0xf
    8000255c:	b6848493          	addi	s1,s1,-1176 # 800110c0 <proc>
            pp->parent = initproc;
    80002560:	00006a17          	auipc	s4,0x6
    80002564:	4b8a0a13          	addi	s4,s4,1208 # 80008a18 <initproc>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002568:	00015997          	auipc	s3,0x15
    8000256c:	95898993          	addi	s3,s3,-1704 # 80016ec0 <tickslock>
    80002570:	a029                	j	8000257a <reparent+0x34>
    80002572:	17848493          	addi	s1,s1,376
    80002576:	01348d63          	beq	s1,s3,80002590 <reparent+0x4a>
        if (pp->parent == p)
    8000257a:	64bc                	ld	a5,72(s1)
    8000257c:	ff279be3          	bne	a5,s2,80002572 <reparent+0x2c>
            pp->parent = initproc;
    80002580:	000a3503          	ld	a0,0(s4)
    80002584:	e4a8                	sd	a0,72(s1)
            wakeup(initproc);
    80002586:	00000097          	auipc	ra,0x0
    8000258a:	f4a080e7          	jalr	-182(ra) # 800024d0 <wakeup>
    8000258e:	b7d5                	j	80002572 <reparent+0x2c>
}
    80002590:	70a2                	ld	ra,40(sp)
    80002592:	7402                	ld	s0,32(sp)
    80002594:	64e2                	ld	s1,24(sp)
    80002596:	6942                	ld	s2,16(sp)
    80002598:	69a2                	ld	s3,8(sp)
    8000259a:	6a02                	ld	s4,0(sp)
    8000259c:	6145                	addi	sp,sp,48
    8000259e:	8082                	ret

00000000800025a0 <exit>:
{
    800025a0:	7179                	addi	sp,sp,-48
    800025a2:	f406                	sd	ra,40(sp)
    800025a4:	f022                	sd	s0,32(sp)
    800025a6:	ec26                	sd	s1,24(sp)
    800025a8:	e84a                	sd	s2,16(sp)
    800025aa:	e44e                	sd	s3,8(sp)
    800025ac:	e052                	sd	s4,0(sp)
    800025ae:	1800                	addi	s0,sp,48
    800025b0:	8a2a                	mv	s4,a0
    struct proc *p = myproc();
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	4d8080e7          	jalr	1240(ra) # 80001a8a <myproc>
    800025ba:	89aa                	mv	s3,a0
    if (p == initproc)
    800025bc:	00006797          	auipc	a5,0x6
    800025c0:	45c7b783          	ld	a5,1116(a5) # 80008a18 <initproc>
    800025c4:	0e050493          	addi	s1,a0,224
    800025c8:	16050913          	addi	s2,a0,352
    800025cc:	02a79363          	bne	a5,a0,800025f2 <exit+0x52>
        panic("init exiting");
    800025d0:	00006517          	auipc	a0,0x6
    800025d4:	c9050513          	addi	a0,a0,-880 # 80008260 <digits+0x220>
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	f68080e7          	jalr	-152(ra) # 80000540 <panic>
            fileclose(f);
    800025e0:	00002097          	auipc	ra,0x2
    800025e4:	4ce080e7          	jalr	1230(ra) # 80004aae <fileclose>
            p->ofile[fd] = 0;
    800025e8:	0004b023          	sd	zero,0(s1)
    for (int fd = 0; fd < NOFILE; fd++)
    800025ec:	04a1                	addi	s1,s1,8
    800025ee:	01248563          	beq	s1,s2,800025f8 <exit+0x58>
        if (p->ofile[fd])
    800025f2:	6088                	ld	a0,0(s1)
    800025f4:	f575                	bnez	a0,800025e0 <exit+0x40>
    800025f6:	bfdd                	j	800025ec <exit+0x4c>
    begin_op();
    800025f8:	00002097          	auipc	ra,0x2
    800025fc:	fee080e7          	jalr	-18(ra) # 800045e6 <begin_op>
    iput(p->cwd);
    80002600:	1609b503          	ld	a0,352(s3)
    80002604:	00001097          	auipc	ra,0x1
    80002608:	7d0080e7          	jalr	2000(ra) # 80003dd4 <iput>
    end_op();
    8000260c:	00002097          	auipc	ra,0x2
    80002610:	058080e7          	jalr	88(ra) # 80004664 <end_op>
    p->cwd = 0;
    80002614:	1609b023          	sd	zero,352(s3)
    acquire(&wait_lock);
    80002618:	0000f497          	auipc	s1,0xf
    8000261c:	a9048493          	addi	s1,s1,-1392 # 800110a8 <wait_lock>
    80002620:	8526                	mv	a0,s1
    80002622:	ffffe097          	auipc	ra,0xffffe
    80002626:	5b4080e7          	jalr	1460(ra) # 80000bd6 <acquire>
    reparent(p);
    8000262a:	854e                	mv	a0,s3
    8000262c:	00000097          	auipc	ra,0x0
    80002630:	f1a080e7          	jalr	-230(ra) # 80002546 <reparent>
    wakeup(p->parent);
    80002634:	0489b503          	ld	a0,72(s3)
    80002638:	00000097          	auipc	ra,0x0
    8000263c:	e98080e7          	jalr	-360(ra) # 800024d0 <wakeup>
    acquire(&p->lock);
    80002640:	854e                	mv	a0,s3
    80002642:	ffffe097          	auipc	ra,0xffffe
    80002646:	594080e7          	jalr	1428(ra) # 80000bd6 <acquire>
    p->xstate = status;
    8000264a:	0349a623          	sw	s4,44(s3)
    p->state = ZOMBIE;
    8000264e:	4795                	li	a5,5
    80002650:	00f9ac23          	sw	a5,24(s3)
    release(&wait_lock);
    80002654:	8526                	mv	a0,s1
    80002656:	ffffe097          	auipc	ra,0xffffe
    8000265a:	634080e7          	jalr	1588(ra) # 80000c8a <release>
    sched();
    8000265e:	00000097          	auipc	ra,0x0
    80002662:	d04080e7          	jalr	-764(ra) # 80002362 <sched>
    panic("zombie exit");
    80002666:	00006517          	auipc	a0,0x6
    8000266a:	c0a50513          	addi	a0,a0,-1014 # 80008270 <digits+0x230>
    8000266e:	ffffe097          	auipc	ra,0xffffe
    80002672:	ed2080e7          	jalr	-302(ra) # 80000540 <panic>

0000000080002676 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002676:	7179                	addi	sp,sp,-48
    80002678:	f406                	sd	ra,40(sp)
    8000267a:	f022                	sd	s0,32(sp)
    8000267c:	ec26                	sd	s1,24(sp)
    8000267e:	e84a                	sd	s2,16(sp)
    80002680:	e44e                	sd	s3,8(sp)
    80002682:	1800                	addi	s0,sp,48
    80002684:	892a                	mv	s2,a0
    struct proc *p;

    for (p = proc; p < &proc[NPROC]; p++)
    80002686:	0000f497          	auipc	s1,0xf
    8000268a:	a3a48493          	addi	s1,s1,-1478 # 800110c0 <proc>
    8000268e:	00015997          	auipc	s3,0x15
    80002692:	83298993          	addi	s3,s3,-1998 # 80016ec0 <tickslock>
    {
        acquire(&p->lock);
    80002696:	8526                	mv	a0,s1
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	53e080e7          	jalr	1342(ra) # 80000bd6 <acquire>
        if (p->pid == pid)
    800026a0:	589c                	lw	a5,48(s1)
    800026a2:	01278d63          	beq	a5,s2,800026bc <kill+0x46>
                p->state = RUNNABLE;
            }
            release(&p->lock);
            return 0;
        }
        release(&p->lock);
    800026a6:	8526                	mv	a0,s1
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	5e2080e7          	jalr	1506(ra) # 80000c8a <release>
    for (p = proc; p < &proc[NPROC]; p++)
    800026b0:	17848493          	addi	s1,s1,376
    800026b4:	ff3491e3          	bne	s1,s3,80002696 <kill+0x20>
    }
    return -1;
    800026b8:	557d                	li	a0,-1
    800026ba:	a829                	j	800026d4 <kill+0x5e>
            p->killed = 1;
    800026bc:	4785                	li	a5,1
    800026be:	d49c                	sw	a5,40(s1)
            if (p->state == SLEEPING)
    800026c0:	4c98                	lw	a4,24(s1)
    800026c2:	4789                	li	a5,2
    800026c4:	00f70f63          	beq	a4,a5,800026e2 <kill+0x6c>
            release(&p->lock);
    800026c8:	8526                	mv	a0,s1
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	5c0080e7          	jalr	1472(ra) # 80000c8a <release>
            return 0;
    800026d2:	4501                	li	a0,0
}
    800026d4:	70a2                	ld	ra,40(sp)
    800026d6:	7402                	ld	s0,32(sp)
    800026d8:	64e2                	ld	s1,24(sp)
    800026da:	6942                	ld	s2,16(sp)
    800026dc:	69a2                	ld	s3,8(sp)
    800026de:	6145                	addi	sp,sp,48
    800026e0:	8082                	ret
                p->state = RUNNABLE;
    800026e2:	478d                	li	a5,3
    800026e4:	cc9c                	sw	a5,24(s1)
    800026e6:	b7cd                	j	800026c8 <kill+0x52>

00000000800026e8 <setkilled>:

void setkilled(struct proc *p)
{
    800026e8:	1101                	addi	sp,sp,-32
    800026ea:	ec06                	sd	ra,24(sp)
    800026ec:	e822                	sd	s0,16(sp)
    800026ee:	e426                	sd	s1,8(sp)
    800026f0:	1000                	addi	s0,sp,32
    800026f2:	84aa                	mv	s1,a0
    acquire(&p->lock);
    800026f4:	ffffe097          	auipc	ra,0xffffe
    800026f8:	4e2080e7          	jalr	1250(ra) # 80000bd6 <acquire>
    p->killed = 1;
    800026fc:	4785                	li	a5,1
    800026fe:	d49c                	sw	a5,40(s1)
    release(&p->lock);
    80002700:	8526                	mv	a0,s1
    80002702:	ffffe097          	auipc	ra,0xffffe
    80002706:	588080e7          	jalr	1416(ra) # 80000c8a <release>
}
    8000270a:	60e2                	ld	ra,24(sp)
    8000270c:	6442                	ld	s0,16(sp)
    8000270e:	64a2                	ld	s1,8(sp)
    80002710:	6105                	addi	sp,sp,32
    80002712:	8082                	ret

0000000080002714 <killed>:

int killed(struct proc *p)
{
    80002714:	1101                	addi	sp,sp,-32
    80002716:	ec06                	sd	ra,24(sp)
    80002718:	e822                	sd	s0,16(sp)
    8000271a:	e426                	sd	s1,8(sp)
    8000271c:	e04a                	sd	s2,0(sp)
    8000271e:	1000                	addi	s0,sp,32
    80002720:	84aa                	mv	s1,a0
    int k;

    acquire(&p->lock);
    80002722:	ffffe097          	auipc	ra,0xffffe
    80002726:	4b4080e7          	jalr	1204(ra) # 80000bd6 <acquire>
    k = p->killed;
    8000272a:	0284a903          	lw	s2,40(s1)
    release(&p->lock);
    8000272e:	8526                	mv	a0,s1
    80002730:	ffffe097          	auipc	ra,0xffffe
    80002734:	55a080e7          	jalr	1370(ra) # 80000c8a <release>
    return k;
}
    80002738:	854a                	mv	a0,s2
    8000273a:	60e2                	ld	ra,24(sp)
    8000273c:	6442                	ld	s0,16(sp)
    8000273e:	64a2                	ld	s1,8(sp)
    80002740:	6902                	ld	s2,0(sp)
    80002742:	6105                	addi	sp,sp,32
    80002744:	8082                	ret

0000000080002746 <wait>:
{
    80002746:	715d                	addi	sp,sp,-80
    80002748:	e486                	sd	ra,72(sp)
    8000274a:	e0a2                	sd	s0,64(sp)
    8000274c:	fc26                	sd	s1,56(sp)
    8000274e:	f84a                	sd	s2,48(sp)
    80002750:	f44e                	sd	s3,40(sp)
    80002752:	f052                	sd	s4,32(sp)
    80002754:	ec56                	sd	s5,24(sp)
    80002756:	e85a                	sd	s6,16(sp)
    80002758:	e45e                	sd	s7,8(sp)
    8000275a:	e062                	sd	s8,0(sp)
    8000275c:	0880                	addi	s0,sp,80
    8000275e:	8b2a                	mv	s6,a0
    struct proc *p = myproc();
    80002760:	fffff097          	auipc	ra,0xfffff
    80002764:	32a080e7          	jalr	810(ra) # 80001a8a <myproc>
    80002768:	892a                	mv	s2,a0
    acquire(&wait_lock);
    8000276a:	0000f517          	auipc	a0,0xf
    8000276e:	93e50513          	addi	a0,a0,-1730 # 800110a8 <wait_lock>
    80002772:	ffffe097          	auipc	ra,0xffffe
    80002776:	464080e7          	jalr	1124(ra) # 80000bd6 <acquire>
        havekids = 0;
    8000277a:	4b81                	li	s7,0
                if (pp->state == ZOMBIE)
    8000277c:	4a15                	li	s4,5
                havekids = 1;
    8000277e:	4a85                	li	s5,1
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002780:	00014997          	auipc	s3,0x14
    80002784:	74098993          	addi	s3,s3,1856 # 80016ec0 <tickslock>
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002788:	0000fc17          	auipc	s8,0xf
    8000278c:	920c0c13          	addi	s8,s8,-1760 # 800110a8 <wait_lock>
        havekids = 0;
    80002790:	875e                	mv	a4,s7
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002792:	0000f497          	auipc	s1,0xf
    80002796:	92e48493          	addi	s1,s1,-1746 # 800110c0 <proc>
    8000279a:	a0bd                	j	80002808 <wait+0xc2>
                    pid = pp->pid;
    8000279c:	0304a983          	lw	s3,48(s1)
                    if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800027a0:	000b0e63          	beqz	s6,800027bc <wait+0x76>
    800027a4:	4691                	li	a3,4
    800027a6:	02c48613          	addi	a2,s1,44
    800027aa:	85da                	mv	a1,s6
    800027ac:	06093503          	ld	a0,96(s2)
    800027b0:	fffff097          	auipc	ra,0xfffff
    800027b4:	ebc080e7          	jalr	-324(ra) # 8000166c <copyout>
    800027b8:	02054563          	bltz	a0,800027e2 <wait+0x9c>
                    freeproc(pp);
    800027bc:	8526                	mv	a0,s1
    800027be:	fffff097          	auipc	ra,0xfffff
    800027c2:	47e080e7          	jalr	1150(ra) # 80001c3c <freeproc>
                    release(&pp->lock);
    800027c6:	8526                	mv	a0,s1
    800027c8:	ffffe097          	auipc	ra,0xffffe
    800027cc:	4c2080e7          	jalr	1218(ra) # 80000c8a <release>
                    release(&wait_lock);
    800027d0:	0000f517          	auipc	a0,0xf
    800027d4:	8d850513          	addi	a0,a0,-1832 # 800110a8 <wait_lock>
    800027d8:	ffffe097          	auipc	ra,0xffffe
    800027dc:	4b2080e7          	jalr	1202(ra) # 80000c8a <release>
                    return pid;
    800027e0:	a0b5                	j	8000284c <wait+0x106>
                        release(&pp->lock);
    800027e2:	8526                	mv	a0,s1
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4a6080e7          	jalr	1190(ra) # 80000c8a <release>
                        release(&wait_lock);
    800027ec:	0000f517          	auipc	a0,0xf
    800027f0:	8bc50513          	addi	a0,a0,-1860 # 800110a8 <wait_lock>
    800027f4:	ffffe097          	auipc	ra,0xffffe
    800027f8:	496080e7          	jalr	1174(ra) # 80000c8a <release>
                        return -1;
    800027fc:	59fd                	li	s3,-1
    800027fe:	a0b9                	j	8000284c <wait+0x106>
        for (pp = proc; pp < &proc[NPROC]; pp++)
    80002800:	17848493          	addi	s1,s1,376
    80002804:	03348463          	beq	s1,s3,8000282c <wait+0xe6>
            if (pp->parent == p)
    80002808:	64bc                	ld	a5,72(s1)
    8000280a:	ff279be3          	bne	a5,s2,80002800 <wait+0xba>
                acquire(&pp->lock);
    8000280e:	8526                	mv	a0,s1
    80002810:	ffffe097          	auipc	ra,0xffffe
    80002814:	3c6080e7          	jalr	966(ra) # 80000bd6 <acquire>
                if (pp->state == ZOMBIE)
    80002818:	4c9c                	lw	a5,24(s1)
    8000281a:	f94781e3          	beq	a5,s4,8000279c <wait+0x56>
                release(&pp->lock);
    8000281e:	8526                	mv	a0,s1
    80002820:	ffffe097          	auipc	ra,0xffffe
    80002824:	46a080e7          	jalr	1130(ra) # 80000c8a <release>
                havekids = 1;
    80002828:	8756                	mv	a4,s5
    8000282a:	bfd9                	j	80002800 <wait+0xba>
        if (!havekids || killed(p))
    8000282c:	c719                	beqz	a4,8000283a <wait+0xf4>
    8000282e:	854a                	mv	a0,s2
    80002830:	00000097          	auipc	ra,0x0
    80002834:	ee4080e7          	jalr	-284(ra) # 80002714 <killed>
    80002838:	c51d                	beqz	a0,80002866 <wait+0x120>
            release(&wait_lock);
    8000283a:	0000f517          	auipc	a0,0xf
    8000283e:	86e50513          	addi	a0,a0,-1938 # 800110a8 <wait_lock>
    80002842:	ffffe097          	auipc	ra,0xffffe
    80002846:	448080e7          	jalr	1096(ra) # 80000c8a <release>
            return -1;
    8000284a:	59fd                	li	s3,-1
}
    8000284c:	854e                	mv	a0,s3
    8000284e:	60a6                	ld	ra,72(sp)
    80002850:	6406                	ld	s0,64(sp)
    80002852:	74e2                	ld	s1,56(sp)
    80002854:	7942                	ld	s2,48(sp)
    80002856:	79a2                	ld	s3,40(sp)
    80002858:	7a02                	ld	s4,32(sp)
    8000285a:	6ae2                	ld	s5,24(sp)
    8000285c:	6b42                	ld	s6,16(sp)
    8000285e:	6ba2                	ld	s7,8(sp)
    80002860:	6c02                	ld	s8,0(sp)
    80002862:	6161                	addi	sp,sp,80
    80002864:	8082                	ret
        sleep(p, &wait_lock); // DOC: wait-sleep
    80002866:	85e2                	mv	a1,s8
    80002868:	854a                	mv	a0,s2
    8000286a:	00000097          	auipc	ra,0x0
    8000286e:	c02080e7          	jalr	-1022(ra) # 8000246c <sleep>
        havekids = 0;
    80002872:	bf39                	j	80002790 <wait+0x4a>

0000000080002874 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002874:	7179                	addi	sp,sp,-48
    80002876:	f406                	sd	ra,40(sp)
    80002878:	f022                	sd	s0,32(sp)
    8000287a:	ec26                	sd	s1,24(sp)
    8000287c:	e84a                	sd	s2,16(sp)
    8000287e:	e44e                	sd	s3,8(sp)
    80002880:	e052                	sd	s4,0(sp)
    80002882:	1800                	addi	s0,sp,48
    80002884:	84aa                	mv	s1,a0
    80002886:	892e                	mv	s2,a1
    80002888:	89b2                	mv	s3,a2
    8000288a:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    8000288c:	fffff097          	auipc	ra,0xfffff
    80002890:	1fe080e7          	jalr	510(ra) # 80001a8a <myproc>
    if (user_dst)
    80002894:	c08d                	beqz	s1,800028b6 <either_copyout+0x42>
    {
        return copyout(p->pagetable, dst, src, len);
    80002896:	86d2                	mv	a3,s4
    80002898:	864e                	mv	a2,s3
    8000289a:	85ca                	mv	a1,s2
    8000289c:	7128                	ld	a0,96(a0)
    8000289e:	fffff097          	auipc	ra,0xfffff
    800028a2:	dce080e7          	jalr	-562(ra) # 8000166c <copyout>
    else
    {
        memmove((char *)dst, src, len);
        return 0;
    }
}
    800028a6:	70a2                	ld	ra,40(sp)
    800028a8:	7402                	ld	s0,32(sp)
    800028aa:	64e2                	ld	s1,24(sp)
    800028ac:	6942                	ld	s2,16(sp)
    800028ae:	69a2                	ld	s3,8(sp)
    800028b0:	6a02                	ld	s4,0(sp)
    800028b2:	6145                	addi	sp,sp,48
    800028b4:	8082                	ret
        memmove((char *)dst, src, len);
    800028b6:	000a061b          	sext.w	a2,s4
    800028ba:	85ce                	mv	a1,s3
    800028bc:	854a                	mv	a0,s2
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	470080e7          	jalr	1136(ra) # 80000d2e <memmove>
        return 0;
    800028c6:	8526                	mv	a0,s1
    800028c8:	bff9                	j	800028a6 <either_copyout+0x32>

00000000800028ca <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800028ca:	7179                	addi	sp,sp,-48
    800028cc:	f406                	sd	ra,40(sp)
    800028ce:	f022                	sd	s0,32(sp)
    800028d0:	ec26                	sd	s1,24(sp)
    800028d2:	e84a                	sd	s2,16(sp)
    800028d4:	e44e                	sd	s3,8(sp)
    800028d6:	e052                	sd	s4,0(sp)
    800028d8:	1800                	addi	s0,sp,48
    800028da:	892a                	mv	s2,a0
    800028dc:	84ae                	mv	s1,a1
    800028de:	89b2                	mv	s3,a2
    800028e0:	8a36                	mv	s4,a3
    struct proc *p = myproc();
    800028e2:	fffff097          	auipc	ra,0xfffff
    800028e6:	1a8080e7          	jalr	424(ra) # 80001a8a <myproc>
    if (user_src)
    800028ea:	c08d                	beqz	s1,8000290c <either_copyin+0x42>
    {
        return copyin(p->pagetable, dst, src, len);
    800028ec:	86d2                	mv	a3,s4
    800028ee:	864e                	mv	a2,s3
    800028f0:	85ca                	mv	a1,s2
    800028f2:	7128                	ld	a0,96(a0)
    800028f4:	fffff097          	auipc	ra,0xfffff
    800028f8:	e04080e7          	jalr	-508(ra) # 800016f8 <copyin>
    else
    {
        memmove(dst, (char *)src, len);
        return 0;
    }
}
    800028fc:	70a2                	ld	ra,40(sp)
    800028fe:	7402                	ld	s0,32(sp)
    80002900:	64e2                	ld	s1,24(sp)
    80002902:	6942                	ld	s2,16(sp)
    80002904:	69a2                	ld	s3,8(sp)
    80002906:	6a02                	ld	s4,0(sp)
    80002908:	6145                	addi	sp,sp,48
    8000290a:	8082                	ret
        memmove(dst, (char *)src, len);
    8000290c:	000a061b          	sext.w	a2,s4
    80002910:	85ce                	mv	a1,s3
    80002912:	854a                	mv	a0,s2
    80002914:	ffffe097          	auipc	ra,0xffffe
    80002918:	41a080e7          	jalr	1050(ra) # 80000d2e <memmove>
        return 0;
    8000291c:	8526                	mv	a0,s1
    8000291e:	bff9                	j	800028fc <either_copyin+0x32>

0000000080002920 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002920:	715d                	addi	sp,sp,-80
    80002922:	e486                	sd	ra,72(sp)
    80002924:	e0a2                	sd	s0,64(sp)
    80002926:	fc26                	sd	s1,56(sp)
    80002928:	f84a                	sd	s2,48(sp)
    8000292a:	f44e                	sd	s3,40(sp)
    8000292c:	f052                	sd	s4,32(sp)
    8000292e:	ec56                	sd	s5,24(sp)
    80002930:	e85a                	sd	s6,16(sp)
    80002932:	e45e                	sd	s7,8(sp)
    80002934:	0880                	addi	s0,sp,80
        [RUNNING] "run   ",
        [ZOMBIE] "zombie"};
    struct proc *p;
    char *state;

    printf("\n");
    80002936:	00005517          	auipc	a0,0x5
    8000293a:	79250513          	addi	a0,a0,1938 # 800080c8 <digits+0x88>
    8000293e:	ffffe097          	auipc	ra,0xffffe
    80002942:	c4c080e7          	jalr	-948(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002946:	0000f497          	auipc	s1,0xf
    8000294a:	8e248493          	addi	s1,s1,-1822 # 80011228 <proc+0x168>
    8000294e:	00014917          	auipc	s2,0x14
    80002952:	6da90913          	addi	s2,s2,1754 # 80017028 <bcache+0x150>
    {
        if (p->state == UNUSED)
            continue;
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002956:	4b15                	li	s6,5
            state = states[p->state];
        else
            state = "???";
    80002958:	00006997          	auipc	s3,0x6
    8000295c:	92898993          	addi	s3,s3,-1752 # 80008280 <digits+0x240>
        printf("%d <%s %s", p->pid, state, p->name);
    80002960:	00006a97          	auipc	s5,0x6
    80002964:	928a8a93          	addi	s5,s5,-1752 # 80008288 <digits+0x248>
        printf("\n");
    80002968:	00005a17          	auipc	s4,0x5
    8000296c:	760a0a13          	addi	s4,s4,1888 # 800080c8 <digits+0x88>
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002970:	00006b97          	auipc	s7,0x6
    80002974:	a28b8b93          	addi	s7,s7,-1496 # 80008398 <states.0>
    80002978:	a00d                	j	8000299a <procdump+0x7a>
        printf("%d <%s %s", p->pid, state, p->name);
    8000297a:	ec86a583          	lw	a1,-312(a3)
    8000297e:	8556                	mv	a0,s5
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	c0a080e7          	jalr	-1014(ra) # 8000058a <printf>
        printf("\n");
    80002988:	8552                	mv	a0,s4
    8000298a:	ffffe097          	auipc	ra,0xffffe
    8000298e:	c00080e7          	jalr	-1024(ra) # 8000058a <printf>
    for (p = proc; p < &proc[NPROC]; p++)
    80002992:	17848493          	addi	s1,s1,376
    80002996:	03248263          	beq	s1,s2,800029ba <procdump+0x9a>
        if (p->state == UNUSED)
    8000299a:	86a6                	mv	a3,s1
    8000299c:	eb04a783          	lw	a5,-336(s1)
    800029a0:	dbed                	beqz	a5,80002992 <procdump+0x72>
            state = "???";
    800029a2:	864e                	mv	a2,s3
        if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800029a4:	fcfb6be3          	bltu	s6,a5,8000297a <procdump+0x5a>
    800029a8:	02079713          	slli	a4,a5,0x20
    800029ac:	01d75793          	srli	a5,a4,0x1d
    800029b0:	97de                	add	a5,a5,s7
    800029b2:	6390                	ld	a2,0(a5)
    800029b4:	f279                	bnez	a2,8000297a <procdump+0x5a>
            state = "???";
    800029b6:	864e                	mv	a2,s3
    800029b8:	b7c9                	j	8000297a <procdump+0x5a>
    }
}
    800029ba:	60a6                	ld	ra,72(sp)
    800029bc:	6406                	ld	s0,64(sp)
    800029be:	74e2                	ld	s1,56(sp)
    800029c0:	7942                	ld	s2,48(sp)
    800029c2:	79a2                	ld	s3,40(sp)
    800029c4:	7a02                	ld	s4,32(sp)
    800029c6:	6ae2                	ld	s5,24(sp)
    800029c8:	6b42                	ld	s6,16(sp)
    800029ca:	6ba2                	ld	s7,8(sp)
    800029cc:	6161                	addi	sp,sp,80
    800029ce:	8082                	ret

00000000800029d0 <schedls>:

void schedls()
{
    800029d0:	1101                	addi	sp,sp,-32
    800029d2:	ec06                	sd	ra,24(sp)
    800029d4:	e822                	sd	s0,16(sp)
    800029d6:	e426                	sd	s1,8(sp)
    800029d8:	1000                	addi	s0,sp,32
    printf("[ ]\tScheduler Name\tScheduler ID\n");
    800029da:	00006517          	auipc	a0,0x6
    800029de:	8be50513          	addi	a0,a0,-1858 # 80008298 <digits+0x258>
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	ba8080e7          	jalr	-1112(ra) # 8000058a <printf>
    printf("====================================\n");
    800029ea:	00006517          	auipc	a0,0x6
    800029ee:	8d650513          	addi	a0,a0,-1834 # 800082c0 <digits+0x280>
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	b98080e7          	jalr	-1128(ra) # 8000058a <printf>
    for (int i = 0; i < SCHEDC; i++)
    {
        if (available_schedulers[i].impl == sched_pointer)
    800029fa:	00006717          	auipc	a4,0x6
    800029fe:	f9e73703          	ld	a4,-98(a4) # 80008998 <available_schedulers+0x10>
    80002a02:	00006797          	auipc	a5,0x6
    80002a06:	f367b783          	ld	a5,-202(a5) # 80008938 <sched_pointer>
    80002a0a:	08f70763          	beq	a4,a5,80002a98 <schedls+0xc8>
        {
            printf("[*]\t");
        }
        else
        {
            printf("   \t");
    80002a0e:	00006517          	auipc	a0,0x6
    80002a12:	8da50513          	addi	a0,a0,-1830 # 800082e8 <digits+0x2a8>
    80002a16:	ffffe097          	auipc	ra,0xffffe
    80002a1a:	b74080e7          	jalr	-1164(ra) # 8000058a <printf>
        }
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a1e:	00006497          	auipc	s1,0x6
    80002a22:	f3248493          	addi	s1,s1,-206 # 80008950 <initcode>
    80002a26:	48b0                	lw	a2,80(s1)
    80002a28:	00006597          	auipc	a1,0x6
    80002a2c:	f6058593          	addi	a1,a1,-160 # 80008988 <available_schedulers>
    80002a30:	00006517          	auipc	a0,0x6
    80002a34:	8c850513          	addi	a0,a0,-1848 # 800082f8 <digits+0x2b8>
    80002a38:	ffffe097          	auipc	ra,0xffffe
    80002a3c:	b52080e7          	jalr	-1198(ra) # 8000058a <printf>
        if (available_schedulers[i].impl == sched_pointer)
    80002a40:	74b8                	ld	a4,104(s1)
    80002a42:	00006797          	auipc	a5,0x6
    80002a46:	ef67b783          	ld	a5,-266(a5) # 80008938 <sched_pointer>
    80002a4a:	06f70063          	beq	a4,a5,80002aaa <schedls+0xda>
            printf("   \t");
    80002a4e:	00006517          	auipc	a0,0x6
    80002a52:	89a50513          	addi	a0,a0,-1894 # 800082e8 <digits+0x2a8>
    80002a56:	ffffe097          	auipc	ra,0xffffe
    80002a5a:	b34080e7          	jalr	-1228(ra) # 8000058a <printf>
        printf("%s\t%d\n", available_schedulers[i].name, available_schedulers[i].id);
    80002a5e:	00006617          	auipc	a2,0x6
    80002a62:	f6262603          	lw	a2,-158(a2) # 800089c0 <available_schedulers+0x38>
    80002a66:	00006597          	auipc	a1,0x6
    80002a6a:	f4258593          	addi	a1,a1,-190 # 800089a8 <available_schedulers+0x20>
    80002a6e:	00006517          	auipc	a0,0x6
    80002a72:	88a50513          	addi	a0,a0,-1910 # 800082f8 <digits+0x2b8>
    80002a76:	ffffe097          	auipc	ra,0xffffe
    80002a7a:	b14080e7          	jalr	-1260(ra) # 8000058a <printf>
    }
    printf("\n*: current scheduler\n\n");
    80002a7e:	00006517          	auipc	a0,0x6
    80002a82:	88250513          	addi	a0,a0,-1918 # 80008300 <digits+0x2c0>
    80002a86:	ffffe097          	auipc	ra,0xffffe
    80002a8a:	b04080e7          	jalr	-1276(ra) # 8000058a <printf>
}
    80002a8e:	60e2                	ld	ra,24(sp)
    80002a90:	6442                	ld	s0,16(sp)
    80002a92:	64a2                	ld	s1,8(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret
            printf("[*]\t");
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	85850513          	addi	a0,a0,-1960 # 800082f0 <digits+0x2b0>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	aea080e7          	jalr	-1302(ra) # 8000058a <printf>
    80002aa8:	bf9d                	j	80002a1e <schedls+0x4e>
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	84650513          	addi	a0,a0,-1978 # 800082f0 <digits+0x2b0>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ad8080e7          	jalr	-1320(ra) # 8000058a <printf>
    80002aba:	b755                	j	80002a5e <schedls+0x8e>

0000000080002abc <schedset>:

void schedset(int id)
{
    80002abc:	1141                	addi	sp,sp,-16
    80002abe:	e406                	sd	ra,8(sp)
    80002ac0:	e022                	sd	s0,0(sp)
    80002ac2:	0800                	addi	s0,sp,16
    if (id < 0 || SCHEDC <= id)
    80002ac4:	4705                	li	a4,1
    80002ac6:	02a76f63          	bltu	a4,a0,80002b04 <schedset+0x48>
    {
        printf("Scheduler unchanged: ID out of range\n");
        return;
    }
    sched_pointer = available_schedulers[id].impl;
    80002aca:	00551793          	slli	a5,a0,0x5
    80002ace:	00006717          	auipc	a4,0x6
    80002ad2:	e8270713          	addi	a4,a4,-382 # 80008950 <initcode>
    80002ad6:	973e                	add	a4,a4,a5
    80002ad8:	6738                	ld	a4,72(a4)
    80002ada:	00006697          	auipc	a3,0x6
    80002ade:	e4e6bf23          	sd	a4,-418(a3) # 80008938 <sched_pointer>
    printf("Scheduler successfully changed to %s\n", available_schedulers[id].name);
    80002ae2:	00006597          	auipc	a1,0x6
    80002ae6:	ea658593          	addi	a1,a1,-346 # 80008988 <available_schedulers>
    80002aea:	95be                	add	a1,a1,a5
    80002aec:	00006517          	auipc	a0,0x6
    80002af0:	85450513          	addi	a0,a0,-1964 # 80008340 <digits+0x300>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a96080e7          	jalr	-1386(ra) # 8000058a <printf>
    80002afc:	60a2                	ld	ra,8(sp)
    80002afe:	6402                	ld	s0,0(sp)
    80002b00:	0141                	addi	sp,sp,16
    80002b02:	8082                	ret
        printf("Scheduler unchanged: ID out of range\n");
    80002b04:	00006517          	auipc	a0,0x6
    80002b08:	81450513          	addi	a0,a0,-2028 # 80008318 <digits+0x2d8>
    80002b0c:	ffffe097          	auipc	ra,0xffffe
    80002b10:	a7e080e7          	jalr	-1410(ra) # 8000058a <printf>
        return;
    80002b14:	b7e5                	j	80002afc <schedset+0x40>

0000000080002b16 <swtch>:
    80002b16:	00153023          	sd	ra,0(a0)
    80002b1a:	00253423          	sd	sp,8(a0)
    80002b1e:	e900                	sd	s0,16(a0)
    80002b20:	ed04                	sd	s1,24(a0)
    80002b22:	03253023          	sd	s2,32(a0)
    80002b26:	03353423          	sd	s3,40(a0)
    80002b2a:	03453823          	sd	s4,48(a0)
    80002b2e:	03553c23          	sd	s5,56(a0)
    80002b32:	05653023          	sd	s6,64(a0)
    80002b36:	05753423          	sd	s7,72(a0)
    80002b3a:	05853823          	sd	s8,80(a0)
    80002b3e:	05953c23          	sd	s9,88(a0)
    80002b42:	07a53023          	sd	s10,96(a0)
    80002b46:	07b53423          	sd	s11,104(a0)
    80002b4a:	0005b083          	ld	ra,0(a1)
    80002b4e:	0085b103          	ld	sp,8(a1)
    80002b52:	6980                	ld	s0,16(a1)
    80002b54:	6d84                	ld	s1,24(a1)
    80002b56:	0205b903          	ld	s2,32(a1)
    80002b5a:	0285b983          	ld	s3,40(a1)
    80002b5e:	0305ba03          	ld	s4,48(a1)
    80002b62:	0385ba83          	ld	s5,56(a1)
    80002b66:	0405bb03          	ld	s6,64(a1)
    80002b6a:	0485bb83          	ld	s7,72(a1)
    80002b6e:	0505bc03          	ld	s8,80(a1)
    80002b72:	0585bc83          	ld	s9,88(a1)
    80002b76:	0605bd03          	ld	s10,96(a1)
    80002b7a:	0685bd83          	ld	s11,104(a1)
    80002b7e:	8082                	ret

0000000080002b80 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002b80:	1141                	addi	sp,sp,-16
    80002b82:	e406                	sd	ra,8(sp)
    80002b84:	e022                	sd	s0,0(sp)
    80002b86:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b88:	00006597          	auipc	a1,0x6
    80002b8c:	84058593          	addi	a1,a1,-1984 # 800083c8 <states.0+0x30>
    80002b90:	00014517          	auipc	a0,0x14
    80002b94:	33050513          	addi	a0,a0,816 # 80016ec0 <tickslock>
    80002b98:	ffffe097          	auipc	ra,0xffffe
    80002b9c:	fae080e7          	jalr	-82(ra) # 80000b46 <initlock>
}
    80002ba0:	60a2                	ld	ra,8(sp)
    80002ba2:	6402                	ld	s0,0(sp)
    80002ba4:	0141                	addi	sp,sp,16
    80002ba6:	8082                	ret

0000000080002ba8 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002ba8:	1141                	addi	sp,sp,-16
    80002baa:	e422                	sd	s0,8(sp)
    80002bac:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bae:	00003797          	auipc	a5,0x3
    80002bb2:	55278793          	addi	a5,a5,1362 # 80006100 <kernelvec>
    80002bb6:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002bba:	6422                	ld	s0,8(sp)
    80002bbc:	0141                	addi	sp,sp,16
    80002bbe:	8082                	ret

0000000080002bc0 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002bc0:	1141                	addi	sp,sp,-16
    80002bc2:	e406                	sd	ra,8(sp)
    80002bc4:	e022                	sd	s0,0(sp)
    80002bc6:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002bc8:	fffff097          	auipc	ra,0xfffff
    80002bcc:	ec2080e7          	jalr	-318(ra) # 80001a8a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bd0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002bd4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002bda:	00004697          	auipc	a3,0x4
    80002bde:	42668693          	addi	a3,a3,1062 # 80007000 <_trampoline>
    80002be2:	00004717          	auipc	a4,0x4
    80002be6:	41e70713          	addi	a4,a4,1054 # 80007000 <_trampoline>
    80002bea:	8f15                	sub	a4,a4,a3
    80002bec:	040007b7          	lui	a5,0x4000
    80002bf0:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002bf2:	07b2                	slli	a5,a5,0xc
    80002bf4:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bf6:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bfa:	7538                	ld	a4,104(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bfc:	18002673          	csrr	a2,satp
    80002c00:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002c02:	7530                	ld	a2,104(a0)
    80002c04:	6938                	ld	a4,80(a0)
    80002c06:	6585                	lui	a1,0x1
    80002c08:	972e                	add	a4,a4,a1
    80002c0a:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002c0c:	7538                	ld	a4,104(a0)
    80002c0e:	00000617          	auipc	a2,0x0
    80002c12:	13060613          	addi	a2,a2,304 # 80002d3e <usertrap>
    80002c16:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002c18:	7538                	ld	a4,104(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002c1a:	8612                	mv	a2,tp
    80002c1c:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c1e:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002c22:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002c26:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c2a:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002c2e:	7538                	ld	a4,104(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c30:	6f18                	ld	a4,24(a4)
    80002c32:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002c36:	7128                	ld	a0,96(a0)
    80002c38:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002c3a:	00004717          	auipc	a4,0x4
    80002c3e:	46270713          	addi	a4,a4,1122 # 8000709c <userret>
    80002c42:	8f15                	sub	a4,a4,a3
    80002c44:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c46:	577d                	li	a4,-1
    80002c48:	177e                	slli	a4,a4,0x3f
    80002c4a:	8d59                	or	a0,a0,a4
    80002c4c:	9782                	jalr	a5
}
    80002c4e:	60a2                	ld	ra,8(sp)
    80002c50:	6402                	ld	s0,0(sp)
    80002c52:	0141                	addi	sp,sp,16
    80002c54:	8082                	ret

0000000080002c56 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002c56:	1101                	addi	sp,sp,-32
    80002c58:	ec06                	sd	ra,24(sp)
    80002c5a:	e822                	sd	s0,16(sp)
    80002c5c:	e426                	sd	s1,8(sp)
    80002c5e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c60:	00014497          	auipc	s1,0x14
    80002c64:	26048493          	addi	s1,s1,608 # 80016ec0 <tickslock>
    80002c68:	8526                	mv	a0,s1
    80002c6a:	ffffe097          	auipc	ra,0xffffe
    80002c6e:	f6c080e7          	jalr	-148(ra) # 80000bd6 <acquire>
  ticks++;
    80002c72:	00006517          	auipc	a0,0x6
    80002c76:	dae50513          	addi	a0,a0,-594 # 80008a20 <ticks>
    80002c7a:	411c                	lw	a5,0(a0)
    80002c7c:	2785                	addiw	a5,a5,1
    80002c7e:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002c80:	00000097          	auipc	ra,0x0
    80002c84:	850080e7          	jalr	-1968(ra) # 800024d0 <wakeup>
  release(&tickslock);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	000080e7          	jalr	ra # 80000c8a <release>
}
    80002c92:	60e2                	ld	ra,24(sp)
    80002c94:	6442                	ld	s0,16(sp)
    80002c96:	64a2                	ld	s1,8(sp)
    80002c98:	6105                	addi	sp,sp,32
    80002c9a:	8082                	ret

0000000080002c9c <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002c9c:	1101                	addi	sp,sp,-32
    80002c9e:	ec06                	sd	ra,24(sp)
    80002ca0:	e822                	sd	s0,16(sp)
    80002ca2:	e426                	sd	s1,8(sp)
    80002ca4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ca6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002caa:	00074d63          	bltz	a4,80002cc4 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002cae:	57fd                	li	a5,-1
    80002cb0:	17fe                	slli	a5,a5,0x3f
    80002cb2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002cb4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002cb6:	06f70363          	beq	a4,a5,80002d1c <devintr+0x80>
  }
}
    80002cba:	60e2                	ld	ra,24(sp)
    80002cbc:	6442                	ld	s0,16(sp)
    80002cbe:	64a2                	ld	s1,8(sp)
    80002cc0:	6105                	addi	sp,sp,32
    80002cc2:	8082                	ret
     (scause & 0xff) == 9){
    80002cc4:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    80002cc8:	46a5                	li	a3,9
    80002cca:	fed792e3          	bne	a5,a3,80002cae <devintr+0x12>
    int irq = plic_claim();
    80002cce:	00003097          	auipc	ra,0x3
    80002cd2:	53a080e7          	jalr	1338(ra) # 80006208 <plic_claim>
    80002cd6:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002cd8:	47a9                	li	a5,10
    80002cda:	02f50763          	beq	a0,a5,80002d08 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002cde:	4785                	li	a5,1
    80002ce0:	02f50963          	beq	a0,a5,80002d12 <devintr+0x76>
    return 1;
    80002ce4:	4505                	li	a0,1
    } else if(irq){
    80002ce6:	d8f1                	beqz	s1,80002cba <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002ce8:	85a6                	mv	a1,s1
    80002cea:	00005517          	auipc	a0,0x5
    80002cee:	6e650513          	addi	a0,a0,1766 # 800083d0 <states.0+0x38>
    80002cf2:	ffffe097          	auipc	ra,0xffffe
    80002cf6:	898080e7          	jalr	-1896(ra) # 8000058a <printf>
      plic_complete(irq);
    80002cfa:	8526                	mv	a0,s1
    80002cfc:	00003097          	auipc	ra,0x3
    80002d00:	530080e7          	jalr	1328(ra) # 8000622c <plic_complete>
    return 1;
    80002d04:	4505                	li	a0,1
    80002d06:	bf55                	j	80002cba <devintr+0x1e>
      uartintr();
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	c90080e7          	jalr	-880(ra) # 80000998 <uartintr>
    80002d10:	b7ed                	j	80002cfa <devintr+0x5e>
      virtio_disk_intr();
    80002d12:	00004097          	auipc	ra,0x4
    80002d16:	9e2080e7          	jalr	-1566(ra) # 800066f4 <virtio_disk_intr>
    80002d1a:	b7c5                	j	80002cfa <devintr+0x5e>
    if(cpuid() == 0){
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	d42080e7          	jalr	-702(ra) # 80001a5e <cpuid>
    80002d24:	c901                	beqz	a0,80002d34 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002d26:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002d2a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002d2c:	14479073          	csrw	sip,a5
    return 2;
    80002d30:	4509                	li	a0,2
    80002d32:	b761                	j	80002cba <devintr+0x1e>
      clockintr();
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	f22080e7          	jalr	-222(ra) # 80002c56 <clockintr>
    80002d3c:	b7ed                	j	80002d26 <devintr+0x8a>

0000000080002d3e <usertrap>:
{
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	e04a                	sd	s2,0(sp)
    80002d48:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d4a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002d4e:	1007f793          	andi	a5,a5,256
    80002d52:	e3b1                	bnez	a5,80002d96 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d54:	00003797          	auipc	a5,0x3
    80002d58:	3ac78793          	addi	a5,a5,940 # 80006100 <kernelvec>
    80002d5c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d60:	fffff097          	auipc	ra,0xfffff
    80002d64:	d2a080e7          	jalr	-726(ra) # 80001a8a <myproc>
    80002d68:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d6a:	753c                	ld	a5,104(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d6c:	14102773          	csrr	a4,sepc
    80002d70:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d72:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002d76:	47a1                	li	a5,8
    80002d78:	02f70763          	beq	a4,a5,80002da6 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002d7c:	00000097          	auipc	ra,0x0
    80002d80:	f20080e7          	jalr	-224(ra) # 80002c9c <devintr>
    80002d84:	892a                	mv	s2,a0
    80002d86:	c151                	beqz	a0,80002e0a <usertrap+0xcc>
  if(killed(p))
    80002d88:	8526                	mv	a0,s1
    80002d8a:	00000097          	auipc	ra,0x0
    80002d8e:	98a080e7          	jalr	-1654(ra) # 80002714 <killed>
    80002d92:	c929                	beqz	a0,80002de4 <usertrap+0xa6>
    80002d94:	a099                	j	80002dda <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002d96:	00005517          	auipc	a0,0x5
    80002d9a:	65a50513          	addi	a0,a0,1626 # 800083f0 <states.0+0x58>
    80002d9e:	ffffd097          	auipc	ra,0xffffd
    80002da2:	7a2080e7          	jalr	1954(ra) # 80000540 <panic>
    if(killed(p))
    80002da6:	00000097          	auipc	ra,0x0
    80002daa:	96e080e7          	jalr	-1682(ra) # 80002714 <killed>
    80002dae:	e921                	bnez	a0,80002dfe <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002db0:	74b8                	ld	a4,104(s1)
    80002db2:	6f1c                	ld	a5,24(a4)
    80002db4:	0791                	addi	a5,a5,4
    80002db6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002dbc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002dc0:	10079073          	csrw	sstatus,a5
    syscall();
    80002dc4:	00000097          	auipc	ra,0x0
    80002dc8:	2d4080e7          	jalr	724(ra) # 80003098 <syscall>
  if(killed(p))
    80002dcc:	8526                	mv	a0,s1
    80002dce:	00000097          	auipc	ra,0x0
    80002dd2:	946080e7          	jalr	-1722(ra) # 80002714 <killed>
    80002dd6:	c911                	beqz	a0,80002dea <usertrap+0xac>
    80002dd8:	4901                	li	s2,0
    exit(-1);
    80002dda:	557d                	li	a0,-1
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	7c4080e7          	jalr	1988(ra) # 800025a0 <exit>
  if(which_dev == 2)
    80002de4:	4789                	li	a5,2
    80002de6:	04f90f63          	beq	s2,a5,80002e44 <usertrap+0x106>
  usertrapret();
    80002dea:	00000097          	auipc	ra,0x0
    80002dee:	dd6080e7          	jalr	-554(ra) # 80002bc0 <usertrapret>
}
    80002df2:	60e2                	ld	ra,24(sp)
    80002df4:	6442                	ld	s0,16(sp)
    80002df6:	64a2                	ld	s1,8(sp)
    80002df8:	6902                	ld	s2,0(sp)
    80002dfa:	6105                	addi	sp,sp,32
    80002dfc:	8082                	ret
      exit(-1);
    80002dfe:	557d                	li	a0,-1
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	7a0080e7          	jalr	1952(ra) # 800025a0 <exit>
    80002e08:	b765                	j	80002db0 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e0a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e0e:	5890                	lw	a2,48(s1)
    80002e10:	00005517          	auipc	a0,0x5
    80002e14:	60050513          	addi	a0,a0,1536 # 80008410 <states.0+0x78>
    80002e18:	ffffd097          	auipc	ra,0xffffd
    80002e1c:	772080e7          	jalr	1906(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e20:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e24:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e28:	00005517          	auipc	a0,0x5
    80002e2c:	61850513          	addi	a0,a0,1560 # 80008440 <states.0+0xa8>
    80002e30:	ffffd097          	auipc	ra,0xffffd
    80002e34:	75a080e7          	jalr	1882(ra) # 8000058a <printf>
    setkilled(p);
    80002e38:	8526                	mv	a0,s1
    80002e3a:	00000097          	auipc	ra,0x0
    80002e3e:	8ae080e7          	jalr	-1874(ra) # 800026e8 <setkilled>
    80002e42:	b769                	j	80002dcc <usertrap+0x8e>
    yield();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	5ec080e7          	jalr	1516(ra) # 80002430 <yield>
    80002e4c:	bf79                	j	80002dea <usertrap+0xac>

0000000080002e4e <kerneltrap>:
{
    80002e4e:	7179                	addi	sp,sp,-48
    80002e50:	f406                	sd	ra,40(sp)
    80002e52:	f022                	sd	s0,32(sp)
    80002e54:	ec26                	sd	s1,24(sp)
    80002e56:	e84a                	sd	s2,16(sp)
    80002e58:	e44e                	sd	s3,8(sp)
    80002e5a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e5c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e60:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e64:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002e68:	1004f793          	andi	a5,s1,256
    80002e6c:	cb85                	beqz	a5,80002e9c <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e6e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e72:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002e74:	ef85                	bnez	a5,80002eac <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002e76:	00000097          	auipc	ra,0x0
    80002e7a:	e26080e7          	jalr	-474(ra) # 80002c9c <devintr>
    80002e7e:	cd1d                	beqz	a0,80002ebc <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002e80:	4789                	li	a5,2
    80002e82:	06f50a63          	beq	a0,a5,80002ef6 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002e86:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002e8a:	10049073          	csrw	sstatus,s1
}
    80002e8e:	70a2                	ld	ra,40(sp)
    80002e90:	7402                	ld	s0,32(sp)
    80002e92:	64e2                	ld	s1,24(sp)
    80002e94:	6942                	ld	s2,16(sp)
    80002e96:	69a2                	ld	s3,8(sp)
    80002e98:	6145                	addi	sp,sp,48
    80002e9a:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002e9c:	00005517          	auipc	a0,0x5
    80002ea0:	5c450513          	addi	a0,a0,1476 # 80008460 <states.0+0xc8>
    80002ea4:	ffffd097          	auipc	ra,0xffffd
    80002ea8:	69c080e7          	jalr	1692(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002eac:	00005517          	auipc	a0,0x5
    80002eb0:	5dc50513          	addi	a0,a0,1500 # 80008488 <states.0+0xf0>
    80002eb4:	ffffd097          	auipc	ra,0xffffd
    80002eb8:	68c080e7          	jalr	1676(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002ebc:	85ce                	mv	a1,s3
    80002ebe:	00005517          	auipc	a0,0x5
    80002ec2:	5ea50513          	addi	a0,a0,1514 # 800084a8 <states.0+0x110>
    80002ec6:	ffffd097          	auipc	ra,0xffffd
    80002eca:	6c4080e7          	jalr	1732(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ece:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ed2:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002ed6:	00005517          	auipc	a0,0x5
    80002eda:	5e250513          	addi	a0,a0,1506 # 800084b8 <states.0+0x120>
    80002ede:	ffffd097          	auipc	ra,0xffffd
    80002ee2:	6ac080e7          	jalr	1708(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002ee6:	00005517          	auipc	a0,0x5
    80002eea:	5ea50513          	addi	a0,a0,1514 # 800084d0 <states.0+0x138>
    80002eee:	ffffd097          	auipc	ra,0xffffd
    80002ef2:	652080e7          	jalr	1618(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ef6:	fffff097          	auipc	ra,0xfffff
    80002efa:	b94080e7          	jalr	-1132(ra) # 80001a8a <myproc>
    80002efe:	d541                	beqz	a0,80002e86 <kerneltrap+0x38>
    80002f00:	fffff097          	auipc	ra,0xfffff
    80002f04:	b8a080e7          	jalr	-1142(ra) # 80001a8a <myproc>
    80002f08:	4d18                	lw	a4,24(a0)
    80002f0a:	4791                	li	a5,4
    80002f0c:	f6f71de3          	bne	a4,a5,80002e86 <kerneltrap+0x38>
    yield();
    80002f10:	fffff097          	auipc	ra,0xfffff
    80002f14:	520080e7          	jalr	1312(ra) # 80002430 <yield>
    80002f18:	b7bd                	j	80002e86 <kerneltrap+0x38>

0000000080002f1a <argraw>:
    return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f1a:	1101                	addi	sp,sp,-32
    80002f1c:	ec06                	sd	ra,24(sp)
    80002f1e:	e822                	sd	s0,16(sp)
    80002f20:	e426                	sd	s1,8(sp)
    80002f22:	1000                	addi	s0,sp,32
    80002f24:	84aa                	mv	s1,a0
    struct proc *p = myproc();
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	b64080e7          	jalr	-1180(ra) # 80001a8a <myproc>
    switch (n)
    80002f2e:	4795                	li	a5,5
    80002f30:	0497e163          	bltu	a5,s1,80002f72 <argraw+0x58>
    80002f34:	048a                	slli	s1,s1,0x2
    80002f36:	00005717          	auipc	a4,0x5
    80002f3a:	5d270713          	addi	a4,a4,1490 # 80008508 <states.0+0x170>
    80002f3e:	94ba                	add	s1,s1,a4
    80002f40:	409c                	lw	a5,0(s1)
    80002f42:	97ba                	add	a5,a5,a4
    80002f44:	8782                	jr	a5
    {
    case 0:
        return p->trapframe->a0;
    80002f46:	753c                	ld	a5,104(a0)
    80002f48:	7ba8                	ld	a0,112(a5)
    case 5:
        return p->trapframe->a5;
    }
    panic("argraw");
    return -1;
}
    80002f4a:	60e2                	ld	ra,24(sp)
    80002f4c:	6442                	ld	s0,16(sp)
    80002f4e:	64a2                	ld	s1,8(sp)
    80002f50:	6105                	addi	sp,sp,32
    80002f52:	8082                	ret
        return p->trapframe->a1;
    80002f54:	753c                	ld	a5,104(a0)
    80002f56:	7fa8                	ld	a0,120(a5)
    80002f58:	bfcd                	j	80002f4a <argraw+0x30>
        return p->trapframe->a2;
    80002f5a:	753c                	ld	a5,104(a0)
    80002f5c:	63c8                	ld	a0,128(a5)
    80002f5e:	b7f5                	j	80002f4a <argraw+0x30>
        return p->trapframe->a3;
    80002f60:	753c                	ld	a5,104(a0)
    80002f62:	67c8                	ld	a0,136(a5)
    80002f64:	b7dd                	j	80002f4a <argraw+0x30>
        return p->trapframe->a4;
    80002f66:	753c                	ld	a5,104(a0)
    80002f68:	6bc8                	ld	a0,144(a5)
    80002f6a:	b7c5                	j	80002f4a <argraw+0x30>
        return p->trapframe->a5;
    80002f6c:	753c                	ld	a5,104(a0)
    80002f6e:	6fc8                	ld	a0,152(a5)
    80002f70:	bfe9                	j	80002f4a <argraw+0x30>
    panic("argraw");
    80002f72:	00005517          	auipc	a0,0x5
    80002f76:	56e50513          	addi	a0,a0,1390 # 800084e0 <states.0+0x148>
    80002f7a:	ffffd097          	auipc	ra,0xffffd
    80002f7e:	5c6080e7          	jalr	1478(ra) # 80000540 <panic>

0000000080002f82 <fetchaddr>:
{
    80002f82:	1101                	addi	sp,sp,-32
    80002f84:	ec06                	sd	ra,24(sp)
    80002f86:	e822                	sd	s0,16(sp)
    80002f88:	e426                	sd	s1,8(sp)
    80002f8a:	e04a                	sd	s2,0(sp)
    80002f8c:	1000                	addi	s0,sp,32
    80002f8e:	84aa                	mv	s1,a0
    80002f90:	892e                	mv	s2,a1
    struct proc *p = myproc();
    80002f92:	fffff097          	auipc	ra,0xfffff
    80002f96:	af8080e7          	jalr	-1288(ra) # 80001a8a <myproc>
    if (addr >= p->sz || addr + sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002f9a:	6d3c                	ld	a5,88(a0)
    80002f9c:	02f4f863          	bgeu	s1,a5,80002fcc <fetchaddr+0x4a>
    80002fa0:	00848713          	addi	a4,s1,8
    80002fa4:	02e7e663          	bltu	a5,a4,80002fd0 <fetchaddr+0x4e>
    if (copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fa8:	46a1                	li	a3,8
    80002faa:	8626                	mv	a2,s1
    80002fac:	85ca                	mv	a1,s2
    80002fae:	7128                	ld	a0,96(a0)
    80002fb0:	ffffe097          	auipc	ra,0xffffe
    80002fb4:	748080e7          	jalr	1864(ra) # 800016f8 <copyin>
    80002fb8:	00a03533          	snez	a0,a0
    80002fbc:	40a00533          	neg	a0,a0
}
    80002fc0:	60e2                	ld	ra,24(sp)
    80002fc2:	6442                	ld	s0,16(sp)
    80002fc4:	64a2                	ld	s1,8(sp)
    80002fc6:	6902                	ld	s2,0(sp)
    80002fc8:	6105                	addi	sp,sp,32
    80002fca:	8082                	ret
        return -1;
    80002fcc:	557d                	li	a0,-1
    80002fce:	bfcd                	j	80002fc0 <fetchaddr+0x3e>
    80002fd0:	557d                	li	a0,-1
    80002fd2:	b7fd                	j	80002fc0 <fetchaddr+0x3e>

0000000080002fd4 <fetchstr>:
{
    80002fd4:	7179                	addi	sp,sp,-48
    80002fd6:	f406                	sd	ra,40(sp)
    80002fd8:	f022                	sd	s0,32(sp)
    80002fda:	ec26                	sd	s1,24(sp)
    80002fdc:	e84a                	sd	s2,16(sp)
    80002fde:	e44e                	sd	s3,8(sp)
    80002fe0:	1800                	addi	s0,sp,48
    80002fe2:	892a                	mv	s2,a0
    80002fe4:	84ae                	mv	s1,a1
    80002fe6:	89b2                	mv	s3,a2
    struct proc *p = myproc();
    80002fe8:	fffff097          	auipc	ra,0xfffff
    80002fec:	aa2080e7          	jalr	-1374(ra) # 80001a8a <myproc>
    if (copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ff0:	86ce                	mv	a3,s3
    80002ff2:	864a                	mv	a2,s2
    80002ff4:	85a6                	mv	a1,s1
    80002ff6:	7128                	ld	a0,96(a0)
    80002ff8:	ffffe097          	auipc	ra,0xffffe
    80002ffc:	78e080e7          	jalr	1934(ra) # 80001786 <copyinstr>
    80003000:	00054e63          	bltz	a0,8000301c <fetchstr+0x48>
    return strlen(buf);
    80003004:	8526                	mv	a0,s1
    80003006:	ffffe097          	auipc	ra,0xffffe
    8000300a:	e48080e7          	jalr	-440(ra) # 80000e4e <strlen>
}
    8000300e:	70a2                	ld	ra,40(sp)
    80003010:	7402                	ld	s0,32(sp)
    80003012:	64e2                	ld	s1,24(sp)
    80003014:	6942                	ld	s2,16(sp)
    80003016:	69a2                	ld	s3,8(sp)
    80003018:	6145                	addi	sp,sp,48
    8000301a:	8082                	ret
        return -1;
    8000301c:	557d                	li	a0,-1
    8000301e:	bfc5                	j	8000300e <fetchstr+0x3a>

0000000080003020 <argint>:

// Fetch the nth 32-bit system call argument.
void argint(int n, int *ip)
{
    80003020:	1101                	addi	sp,sp,-32
    80003022:	ec06                	sd	ra,24(sp)
    80003024:	e822                	sd	s0,16(sp)
    80003026:	e426                	sd	s1,8(sp)
    80003028:	1000                	addi	s0,sp,32
    8000302a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000302c:	00000097          	auipc	ra,0x0
    80003030:	eee080e7          	jalr	-274(ra) # 80002f1a <argraw>
    80003034:	c088                	sw	a0,0(s1)
}
    80003036:	60e2                	ld	ra,24(sp)
    80003038:	6442                	ld	s0,16(sp)
    8000303a:	64a2                	ld	s1,8(sp)
    8000303c:	6105                	addi	sp,sp,32
    8000303e:	8082                	ret

0000000080003040 <argaddr>:

// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void argaddr(int n, uint64 *ip)
{
    80003040:	1101                	addi	sp,sp,-32
    80003042:	ec06                	sd	ra,24(sp)
    80003044:	e822                	sd	s0,16(sp)
    80003046:	e426                	sd	s1,8(sp)
    80003048:	1000                	addi	s0,sp,32
    8000304a:	84ae                	mv	s1,a1
    *ip = argraw(n);
    8000304c:	00000097          	auipc	ra,0x0
    80003050:	ece080e7          	jalr	-306(ra) # 80002f1a <argraw>
    80003054:	e088                	sd	a0,0(s1)
}
    80003056:	60e2                	ld	ra,24(sp)
    80003058:	6442                	ld	s0,16(sp)
    8000305a:	64a2                	ld	s1,8(sp)
    8000305c:	6105                	addi	sp,sp,32
    8000305e:	8082                	ret

0000000080003060 <argstr>:

// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int argstr(int n, char *buf, int max)
{
    80003060:	7179                	addi	sp,sp,-48
    80003062:	f406                	sd	ra,40(sp)
    80003064:	f022                	sd	s0,32(sp)
    80003066:	ec26                	sd	s1,24(sp)
    80003068:	e84a                	sd	s2,16(sp)
    8000306a:	1800                	addi	s0,sp,48
    8000306c:	84ae                	mv	s1,a1
    8000306e:	8932                	mv	s2,a2
    uint64 addr;
    argaddr(n, &addr);
    80003070:	fd840593          	addi	a1,s0,-40
    80003074:	00000097          	auipc	ra,0x0
    80003078:	fcc080e7          	jalr	-52(ra) # 80003040 <argaddr>
    return fetchstr(addr, buf, max);
    8000307c:	864a                	mv	a2,s2
    8000307e:	85a6                	mv	a1,s1
    80003080:	fd843503          	ld	a0,-40(s0)
    80003084:	00000097          	auipc	ra,0x0
    80003088:	f50080e7          	jalr	-176(ra) # 80002fd4 <fetchstr>
}
    8000308c:	70a2                	ld	ra,40(sp)
    8000308e:	7402                	ld	s0,32(sp)
    80003090:	64e2                	ld	s1,24(sp)
    80003092:	6942                	ld	s2,16(sp)
    80003094:	6145                	addi	sp,sp,48
    80003096:	8082                	ret

0000000080003098 <syscall>:
    [SYS_schedls] sys_schedls,
    [SYS_schedset] sys_schedset,
};

void syscall(void)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	e04a                	sd	s2,0(sp)
    800030a2:	1000                	addi	s0,sp,32
    int num;
    struct proc *p = myproc();
    800030a4:	fffff097          	auipc	ra,0xfffff
    800030a8:	9e6080e7          	jalr	-1562(ra) # 80001a8a <myproc>
    800030ac:	84aa                	mv	s1,a0

    num = p->trapframe->a7;
    800030ae:	06853903          	ld	s2,104(a0)
    800030b2:	0a893783          	ld	a5,168(s2)
    800030b6:	0007869b          	sext.w	a3,a5
    if (num > 0 && num < NELEM(syscalls) && syscalls[num])
    800030ba:	37fd                	addiw	a5,a5,-1
    800030bc:	475d                	li	a4,23
    800030be:	00f76f63          	bltu	a4,a5,800030dc <syscall+0x44>
    800030c2:	00369713          	slli	a4,a3,0x3
    800030c6:	00005797          	auipc	a5,0x5
    800030ca:	45a78793          	addi	a5,a5,1114 # 80008520 <syscalls>
    800030ce:	97ba                	add	a5,a5,a4
    800030d0:	639c                	ld	a5,0(a5)
    800030d2:	c789                	beqz	a5,800030dc <syscall+0x44>
    {
        // Use num to lookup the system call function for num, call it,
        // and store its return value in p->trapframe->a0
        p->trapframe->a0 = syscalls[num]();
    800030d4:	9782                	jalr	a5
    800030d6:	06a93823          	sd	a0,112(s2)
    800030da:	a839                	j	800030f8 <syscall+0x60>
    }
    else
    {
        printf("%d %s: unknown sys call %d\n",
    800030dc:	16848613          	addi	a2,s1,360
    800030e0:	588c                	lw	a1,48(s1)
    800030e2:	00005517          	auipc	a0,0x5
    800030e6:	40650513          	addi	a0,a0,1030 # 800084e8 <states.0+0x150>
    800030ea:	ffffd097          	auipc	ra,0xffffd
    800030ee:	4a0080e7          	jalr	1184(ra) # 8000058a <printf>
               p->pid, p->name, num);
        p->trapframe->a0 = -1;
    800030f2:	74bc                	ld	a5,104(s1)
    800030f4:	577d                	li	a4,-1
    800030f6:	fbb8                	sd	a4,112(a5)
    }
}
    800030f8:	60e2                	ld	ra,24(sp)
    800030fa:	6442                	ld	s0,16(sp)
    800030fc:	64a2                	ld	s1,8(sp)
    800030fe:	6902                	ld	s2,0(sp)
    80003100:	6105                	addi	sp,sp,32
    80003102:	8082                	ret

0000000080003104 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80003104:	1101                	addi	sp,sp,-32
    80003106:	ec06                	sd	ra,24(sp)
    80003108:	e822                	sd	s0,16(sp)
    8000310a:	1000                	addi	s0,sp,32
    int n;
    argint(0, &n);
    8000310c:	fec40593          	addi	a1,s0,-20
    80003110:	4501                	li	a0,0
    80003112:	00000097          	auipc	ra,0x0
    80003116:	f0e080e7          	jalr	-242(ra) # 80003020 <argint>
    exit(n);
    8000311a:	fec42503          	lw	a0,-20(s0)
    8000311e:	fffff097          	auipc	ra,0xfffff
    80003122:	482080e7          	jalr	1154(ra) # 800025a0 <exit>
    return 0; // not reached
}
    80003126:	4501                	li	a0,0
    80003128:	60e2                	ld	ra,24(sp)
    8000312a:	6442                	ld	s0,16(sp)
    8000312c:	6105                	addi	sp,sp,32
    8000312e:	8082                	ret

0000000080003130 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003130:	1141                	addi	sp,sp,-16
    80003132:	e406                	sd	ra,8(sp)
    80003134:	e022                	sd	s0,0(sp)
    80003136:	0800                	addi	s0,sp,16
    return myproc()->pid;
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	952080e7          	jalr	-1710(ra) # 80001a8a <myproc>
}
    80003140:	5908                	lw	a0,48(a0)
    80003142:	60a2                	ld	ra,8(sp)
    80003144:	6402                	ld	s0,0(sp)
    80003146:	0141                	addi	sp,sp,16
    80003148:	8082                	ret

000000008000314a <sys_fork>:

uint64
sys_fork(void)
{
    8000314a:	1141                	addi	sp,sp,-16
    8000314c:	e406                	sd	ra,8(sp)
    8000314e:	e022                	sd	s0,0(sp)
    80003150:	0800                	addi	s0,sp,16
    return fork();
    80003152:	fffff097          	auipc	ra,0xfffff
    80003156:	e42080e7          	jalr	-446(ra) # 80001f94 <fork>
}
    8000315a:	60a2                	ld	ra,8(sp)
    8000315c:	6402                	ld	s0,0(sp)
    8000315e:	0141                	addi	sp,sp,16
    80003160:	8082                	ret

0000000080003162 <sys_wait>:

uint64
sys_wait(void)
{
    80003162:	1101                	addi	sp,sp,-32
    80003164:	ec06                	sd	ra,24(sp)
    80003166:	e822                	sd	s0,16(sp)
    80003168:	1000                	addi	s0,sp,32
    uint64 p;
    argaddr(0, &p);
    8000316a:	fe840593          	addi	a1,s0,-24
    8000316e:	4501                	li	a0,0
    80003170:	00000097          	auipc	ra,0x0
    80003174:	ed0080e7          	jalr	-304(ra) # 80003040 <argaddr>
    return wait(p);
    80003178:	fe843503          	ld	a0,-24(s0)
    8000317c:	fffff097          	auipc	ra,0xfffff
    80003180:	5ca080e7          	jalr	1482(ra) # 80002746 <wait>
}
    80003184:	60e2                	ld	ra,24(sp)
    80003186:	6442                	ld	s0,16(sp)
    80003188:	6105                	addi	sp,sp,32
    8000318a:	8082                	ret

000000008000318c <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000318c:	7179                	addi	sp,sp,-48
    8000318e:	f406                	sd	ra,40(sp)
    80003190:	f022                	sd	s0,32(sp)
    80003192:	ec26                	sd	s1,24(sp)
    80003194:	1800                	addi	s0,sp,48
    uint64 addr;
    int n;

    argint(0, &n);
    80003196:	fdc40593          	addi	a1,s0,-36
    8000319a:	4501                	li	a0,0
    8000319c:	00000097          	auipc	ra,0x0
    800031a0:	e84080e7          	jalr	-380(ra) # 80003020 <argint>
    addr = myproc()->sz;
    800031a4:	fffff097          	auipc	ra,0xfffff
    800031a8:	8e6080e7          	jalr	-1818(ra) # 80001a8a <myproc>
    800031ac:	6d24                	ld	s1,88(a0)
    if (growproc(n) < 0)
    800031ae:	fdc42503          	lw	a0,-36(s0)
    800031b2:	fffff097          	auipc	ra,0xfffff
    800031b6:	c36080e7          	jalr	-970(ra) # 80001de8 <growproc>
    800031ba:	00054863          	bltz	a0,800031ca <sys_sbrk+0x3e>
        return -1;
    return addr;
}
    800031be:	8526                	mv	a0,s1
    800031c0:	70a2                	ld	ra,40(sp)
    800031c2:	7402                	ld	s0,32(sp)
    800031c4:	64e2                	ld	s1,24(sp)
    800031c6:	6145                	addi	sp,sp,48
    800031c8:	8082                	ret
        return -1;
    800031ca:	54fd                	li	s1,-1
    800031cc:	bfcd                	j	800031be <sys_sbrk+0x32>

00000000800031ce <sys_sleep>:

uint64
sys_sleep(void)
{
    800031ce:	7139                	addi	sp,sp,-64
    800031d0:	fc06                	sd	ra,56(sp)
    800031d2:	f822                	sd	s0,48(sp)
    800031d4:	f426                	sd	s1,40(sp)
    800031d6:	f04a                	sd	s2,32(sp)
    800031d8:	ec4e                	sd	s3,24(sp)
    800031da:	0080                	addi	s0,sp,64
    int n;
    uint ticks0;

    argint(0, &n);
    800031dc:	fcc40593          	addi	a1,s0,-52
    800031e0:	4501                	li	a0,0
    800031e2:	00000097          	auipc	ra,0x0
    800031e6:	e3e080e7          	jalr	-450(ra) # 80003020 <argint>
    acquire(&tickslock);
    800031ea:	00014517          	auipc	a0,0x14
    800031ee:	cd650513          	addi	a0,a0,-810 # 80016ec0 <tickslock>
    800031f2:	ffffe097          	auipc	ra,0xffffe
    800031f6:	9e4080e7          	jalr	-1564(ra) # 80000bd6 <acquire>
    ticks0 = ticks;
    800031fa:	00006917          	auipc	s2,0x6
    800031fe:	82692903          	lw	s2,-2010(s2) # 80008a20 <ticks>
    while (ticks - ticks0 < n)
    80003202:	fcc42783          	lw	a5,-52(s0)
    80003206:	cf9d                	beqz	a5,80003244 <sys_sleep+0x76>
        if (killed(myproc()))
        {
            release(&tickslock);
            return -1;
        }
        sleep(&ticks, &tickslock);
    80003208:	00014997          	auipc	s3,0x14
    8000320c:	cb898993          	addi	s3,s3,-840 # 80016ec0 <tickslock>
    80003210:	00006497          	auipc	s1,0x6
    80003214:	81048493          	addi	s1,s1,-2032 # 80008a20 <ticks>
        if (killed(myproc()))
    80003218:	fffff097          	auipc	ra,0xfffff
    8000321c:	872080e7          	jalr	-1934(ra) # 80001a8a <myproc>
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	4f4080e7          	jalr	1268(ra) # 80002714 <killed>
    80003228:	ed15                	bnez	a0,80003264 <sys_sleep+0x96>
        sleep(&ticks, &tickslock);
    8000322a:	85ce                	mv	a1,s3
    8000322c:	8526                	mv	a0,s1
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	23e080e7          	jalr	574(ra) # 8000246c <sleep>
    while (ticks - ticks0 < n)
    80003236:	409c                	lw	a5,0(s1)
    80003238:	412787bb          	subw	a5,a5,s2
    8000323c:	fcc42703          	lw	a4,-52(s0)
    80003240:	fce7ece3          	bltu	a5,a4,80003218 <sys_sleep+0x4a>
    }
    release(&tickslock);
    80003244:	00014517          	auipc	a0,0x14
    80003248:	c7c50513          	addi	a0,a0,-900 # 80016ec0 <tickslock>
    8000324c:	ffffe097          	auipc	ra,0xffffe
    80003250:	a3e080e7          	jalr	-1474(ra) # 80000c8a <release>
    return 0;
    80003254:	4501                	li	a0,0
}
    80003256:	70e2                	ld	ra,56(sp)
    80003258:	7442                	ld	s0,48(sp)
    8000325a:	74a2                	ld	s1,40(sp)
    8000325c:	7902                	ld	s2,32(sp)
    8000325e:	69e2                	ld	s3,24(sp)
    80003260:	6121                	addi	sp,sp,64
    80003262:	8082                	ret
            release(&tickslock);
    80003264:	00014517          	auipc	a0,0x14
    80003268:	c5c50513          	addi	a0,a0,-932 # 80016ec0 <tickslock>
    8000326c:	ffffe097          	auipc	ra,0xffffe
    80003270:	a1e080e7          	jalr	-1506(ra) # 80000c8a <release>
            return -1;
    80003274:	557d                	li	a0,-1
    80003276:	b7c5                	j	80003256 <sys_sleep+0x88>

0000000080003278 <sys_kill>:

uint64
sys_kill(void)
{
    80003278:	1101                	addi	sp,sp,-32
    8000327a:	ec06                	sd	ra,24(sp)
    8000327c:	e822                	sd	s0,16(sp)
    8000327e:	1000                	addi	s0,sp,32
    int pid;

    argint(0, &pid);
    80003280:	fec40593          	addi	a1,s0,-20
    80003284:	4501                	li	a0,0
    80003286:	00000097          	auipc	ra,0x0
    8000328a:	d9a080e7          	jalr	-614(ra) # 80003020 <argint>
    return kill(pid);
    8000328e:	fec42503          	lw	a0,-20(s0)
    80003292:	fffff097          	auipc	ra,0xfffff
    80003296:	3e4080e7          	jalr	996(ra) # 80002676 <kill>
}
    8000329a:	60e2                	ld	ra,24(sp)
    8000329c:	6442                	ld	s0,16(sp)
    8000329e:	6105                	addi	sp,sp,32
    800032a0:	8082                	ret

00000000800032a2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800032a2:	1101                	addi	sp,sp,-32
    800032a4:	ec06                	sd	ra,24(sp)
    800032a6:	e822                	sd	s0,16(sp)
    800032a8:	e426                	sd	s1,8(sp)
    800032aa:	1000                	addi	s0,sp,32
    uint xticks;

    acquire(&tickslock);
    800032ac:	00014517          	auipc	a0,0x14
    800032b0:	c1450513          	addi	a0,a0,-1004 # 80016ec0 <tickslock>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	922080e7          	jalr	-1758(ra) # 80000bd6 <acquire>
    xticks = ticks;
    800032bc:	00005497          	auipc	s1,0x5
    800032c0:	7644a483          	lw	s1,1892(s1) # 80008a20 <ticks>
    release(&tickslock);
    800032c4:	00014517          	auipc	a0,0x14
    800032c8:	bfc50513          	addi	a0,a0,-1028 # 80016ec0 <tickslock>
    800032cc:	ffffe097          	auipc	ra,0xffffe
    800032d0:	9be080e7          	jalr	-1602(ra) # 80000c8a <release>
    return xticks;
}
    800032d4:	02049513          	slli	a0,s1,0x20
    800032d8:	9101                	srli	a0,a0,0x20
    800032da:	60e2                	ld	ra,24(sp)
    800032dc:	6442                	ld	s0,16(sp)
    800032de:	64a2                	ld	s1,8(sp)
    800032e0:	6105                	addi	sp,sp,32
    800032e2:	8082                	ret

00000000800032e4 <sys_ps>:

void *
sys_ps(void)
{
    800032e4:	1101                	addi	sp,sp,-32
    800032e6:	ec06                	sd	ra,24(sp)
    800032e8:	e822                	sd	s0,16(sp)
    800032ea:	1000                	addi	s0,sp,32
    int start = 0, count = 0;
    800032ec:	fe042623          	sw	zero,-20(s0)
    800032f0:	fe042423          	sw	zero,-24(s0)
    argint(0, &start);
    800032f4:	fec40593          	addi	a1,s0,-20
    800032f8:	4501                	li	a0,0
    800032fa:	00000097          	auipc	ra,0x0
    800032fe:	d26080e7          	jalr	-730(ra) # 80003020 <argint>
    argint(1, &count);
    80003302:	fe840593          	addi	a1,s0,-24
    80003306:	4505                	li	a0,1
    80003308:	00000097          	auipc	ra,0x0
    8000330c:	d18080e7          	jalr	-744(ra) # 80003020 <argint>
    return ps((uint8)start, (uint8)count);
    80003310:	fe844583          	lbu	a1,-24(s0)
    80003314:	fec44503          	lbu	a0,-20(s0)
    80003318:	fffff097          	auipc	ra,0xfffff
    8000331c:	b2c080e7          	jalr	-1236(ra) # 80001e44 <ps>
}
    80003320:	60e2                	ld	ra,24(sp)
    80003322:	6442                	ld	s0,16(sp)
    80003324:	6105                	addi	sp,sp,32
    80003326:	8082                	ret

0000000080003328 <sys_schedls>:

uint64 sys_schedls(void)
{
    80003328:	1141                	addi	sp,sp,-16
    8000332a:	e406                	sd	ra,8(sp)
    8000332c:	e022                	sd	s0,0(sp)
    8000332e:	0800                	addi	s0,sp,16
    schedls();
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	6a0080e7          	jalr	1696(ra) # 800029d0 <schedls>
    return 0;
}
    80003338:	4501                	li	a0,0
    8000333a:	60a2                	ld	ra,8(sp)
    8000333c:	6402                	ld	s0,0(sp)
    8000333e:	0141                	addi	sp,sp,16
    80003340:	8082                	ret

0000000080003342 <sys_schedset>:

uint64 sys_schedset(void)
{
    80003342:	1101                	addi	sp,sp,-32
    80003344:	ec06                	sd	ra,24(sp)
    80003346:	e822                	sd	s0,16(sp)
    80003348:	1000                	addi	s0,sp,32
    int id = 0;
    8000334a:	fe042623          	sw	zero,-20(s0)
    argint(0, &id);
    8000334e:	fec40593          	addi	a1,s0,-20
    80003352:	4501                	li	a0,0
    80003354:	00000097          	auipc	ra,0x0
    80003358:	ccc080e7          	jalr	-820(ra) # 80003020 <argint>
    schedset(id - 1);
    8000335c:	fec42503          	lw	a0,-20(s0)
    80003360:	357d                	addiw	a0,a0,-1
    80003362:	fffff097          	auipc	ra,0xfffff
    80003366:	75a080e7          	jalr	1882(ra) # 80002abc <schedset>
    return 0;
    8000336a:	4501                	li	a0,0
    8000336c:	60e2                	ld	ra,24(sp)
    8000336e:	6442                	ld	s0,16(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret

0000000080003374 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003374:	7179                	addi	sp,sp,-48
    80003376:	f406                	sd	ra,40(sp)
    80003378:	f022                	sd	s0,32(sp)
    8000337a:	ec26                	sd	s1,24(sp)
    8000337c:	e84a                	sd	s2,16(sp)
    8000337e:	e44e                	sd	s3,8(sp)
    80003380:	e052                	sd	s4,0(sp)
    80003382:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003384:	00005597          	auipc	a1,0x5
    80003388:	26458593          	addi	a1,a1,612 # 800085e8 <syscalls+0xc8>
    8000338c:	00014517          	auipc	a0,0x14
    80003390:	b4c50513          	addi	a0,a0,-1204 # 80016ed8 <bcache>
    80003394:	ffffd097          	auipc	ra,0xffffd
    80003398:	7b2080e7          	jalr	1970(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000339c:	0001c797          	auipc	a5,0x1c
    800033a0:	b3c78793          	addi	a5,a5,-1220 # 8001eed8 <bcache+0x8000>
    800033a4:	0001c717          	auipc	a4,0x1c
    800033a8:	d9c70713          	addi	a4,a4,-612 # 8001f140 <bcache+0x8268>
    800033ac:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    800033b0:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033b4:	00014497          	auipc	s1,0x14
    800033b8:	b3c48493          	addi	s1,s1,-1220 # 80016ef0 <bcache+0x18>
    b->next = bcache.head.next;
    800033bc:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    800033be:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    800033c0:	00005a17          	auipc	s4,0x5
    800033c4:	230a0a13          	addi	s4,s4,560 # 800085f0 <syscalls+0xd0>
    b->next = bcache.head.next;
    800033c8:	2b893783          	ld	a5,696(s2)
    800033cc:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800033ce:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800033d2:	85d2                	mv	a1,s4
    800033d4:	01048513          	addi	a0,s1,16
    800033d8:	00001097          	auipc	ra,0x1
    800033dc:	4c8080e7          	jalr	1224(ra) # 800048a0 <initsleeplock>
    bcache.head.next->prev = b;
    800033e0:	2b893783          	ld	a5,696(s2)
    800033e4:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800033e6:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800033ea:	45848493          	addi	s1,s1,1112
    800033ee:	fd349de3          	bne	s1,s3,800033c8 <binit+0x54>
  }
}
    800033f2:	70a2                	ld	ra,40(sp)
    800033f4:	7402                	ld	s0,32(sp)
    800033f6:	64e2                	ld	s1,24(sp)
    800033f8:	6942                	ld	s2,16(sp)
    800033fa:	69a2                	ld	s3,8(sp)
    800033fc:	6a02                	ld	s4,0(sp)
    800033fe:	6145                	addi	sp,sp,48
    80003400:	8082                	ret

0000000080003402 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003402:	7179                	addi	sp,sp,-48
    80003404:	f406                	sd	ra,40(sp)
    80003406:	f022                	sd	s0,32(sp)
    80003408:	ec26                	sd	s1,24(sp)
    8000340a:	e84a                	sd	s2,16(sp)
    8000340c:	e44e                	sd	s3,8(sp)
    8000340e:	1800                	addi	s0,sp,48
    80003410:	892a                	mv	s2,a0
    80003412:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003414:	00014517          	auipc	a0,0x14
    80003418:	ac450513          	addi	a0,a0,-1340 # 80016ed8 <bcache>
    8000341c:	ffffd097          	auipc	ra,0xffffd
    80003420:	7ba080e7          	jalr	1978(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003424:	0001c497          	auipc	s1,0x1c
    80003428:	d6c4b483          	ld	s1,-660(s1) # 8001f190 <bcache+0x82b8>
    8000342c:	0001c797          	auipc	a5,0x1c
    80003430:	d1478793          	addi	a5,a5,-748 # 8001f140 <bcache+0x8268>
    80003434:	02f48f63          	beq	s1,a5,80003472 <bread+0x70>
    80003438:	873e                	mv	a4,a5
    8000343a:	a021                	j	80003442 <bread+0x40>
    8000343c:	68a4                	ld	s1,80(s1)
    8000343e:	02e48a63          	beq	s1,a4,80003472 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003442:	449c                	lw	a5,8(s1)
    80003444:	ff279ce3          	bne	a5,s2,8000343c <bread+0x3a>
    80003448:	44dc                	lw	a5,12(s1)
    8000344a:	ff3799e3          	bne	a5,s3,8000343c <bread+0x3a>
      b->refcnt++;
    8000344e:	40bc                	lw	a5,64(s1)
    80003450:	2785                	addiw	a5,a5,1
    80003452:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003454:	00014517          	auipc	a0,0x14
    80003458:	a8450513          	addi	a0,a0,-1404 # 80016ed8 <bcache>
    8000345c:	ffffe097          	auipc	ra,0xffffe
    80003460:	82e080e7          	jalr	-2002(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003464:	01048513          	addi	a0,s1,16
    80003468:	00001097          	auipc	ra,0x1
    8000346c:	472080e7          	jalr	1138(ra) # 800048da <acquiresleep>
      return b;
    80003470:	a8b9                	j	800034ce <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003472:	0001c497          	auipc	s1,0x1c
    80003476:	d164b483          	ld	s1,-746(s1) # 8001f188 <bcache+0x82b0>
    8000347a:	0001c797          	auipc	a5,0x1c
    8000347e:	cc678793          	addi	a5,a5,-826 # 8001f140 <bcache+0x8268>
    80003482:	00f48863          	beq	s1,a5,80003492 <bread+0x90>
    80003486:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003488:	40bc                	lw	a5,64(s1)
    8000348a:	cf81                	beqz	a5,800034a2 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000348c:	64a4                	ld	s1,72(s1)
    8000348e:	fee49de3          	bne	s1,a4,80003488 <bread+0x86>
  panic("bget: no buffers");
    80003492:	00005517          	auipc	a0,0x5
    80003496:	16650513          	addi	a0,a0,358 # 800085f8 <syscalls+0xd8>
    8000349a:	ffffd097          	auipc	ra,0xffffd
    8000349e:	0a6080e7          	jalr	166(ra) # 80000540 <panic>
      b->dev = dev;
    800034a2:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    800034a6:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    800034aa:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800034ae:	4785                	li	a5,1
    800034b0:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800034b2:	00014517          	auipc	a0,0x14
    800034b6:	a2650513          	addi	a0,a0,-1498 # 80016ed8 <bcache>
    800034ba:	ffffd097          	auipc	ra,0xffffd
    800034be:	7d0080e7          	jalr	2000(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800034c2:	01048513          	addi	a0,s1,16
    800034c6:	00001097          	auipc	ra,0x1
    800034ca:	414080e7          	jalr	1044(ra) # 800048da <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800034ce:	409c                	lw	a5,0(s1)
    800034d0:	cb89                	beqz	a5,800034e2 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800034d2:	8526                	mv	a0,s1
    800034d4:	70a2                	ld	ra,40(sp)
    800034d6:	7402                	ld	s0,32(sp)
    800034d8:	64e2                	ld	s1,24(sp)
    800034da:	6942                	ld	s2,16(sp)
    800034dc:	69a2                	ld	s3,8(sp)
    800034de:	6145                	addi	sp,sp,48
    800034e0:	8082                	ret
    virtio_disk_rw(b, 0);
    800034e2:	4581                	li	a1,0
    800034e4:	8526                	mv	a0,s1
    800034e6:	00003097          	auipc	ra,0x3
    800034ea:	fdc080e7          	jalr	-36(ra) # 800064c2 <virtio_disk_rw>
    b->valid = 1;
    800034ee:	4785                	li	a5,1
    800034f0:	c09c                	sw	a5,0(s1)
  return b;
    800034f2:	b7c5                	j	800034d2 <bread+0xd0>

00000000800034f4 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800034f4:	1101                	addi	sp,sp,-32
    800034f6:	ec06                	sd	ra,24(sp)
    800034f8:	e822                	sd	s0,16(sp)
    800034fa:	e426                	sd	s1,8(sp)
    800034fc:	1000                	addi	s0,sp,32
    800034fe:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003500:	0541                	addi	a0,a0,16
    80003502:	00001097          	auipc	ra,0x1
    80003506:	472080e7          	jalr	1138(ra) # 80004974 <holdingsleep>
    8000350a:	cd01                	beqz	a0,80003522 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000350c:	4585                	li	a1,1
    8000350e:	8526                	mv	a0,s1
    80003510:	00003097          	auipc	ra,0x3
    80003514:	fb2080e7          	jalr	-78(ra) # 800064c2 <virtio_disk_rw>
}
    80003518:	60e2                	ld	ra,24(sp)
    8000351a:	6442                	ld	s0,16(sp)
    8000351c:	64a2                	ld	s1,8(sp)
    8000351e:	6105                	addi	sp,sp,32
    80003520:	8082                	ret
    panic("bwrite");
    80003522:	00005517          	auipc	a0,0x5
    80003526:	0ee50513          	addi	a0,a0,238 # 80008610 <syscalls+0xf0>
    8000352a:	ffffd097          	auipc	ra,0xffffd
    8000352e:	016080e7          	jalr	22(ra) # 80000540 <panic>

0000000080003532 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003532:	1101                	addi	sp,sp,-32
    80003534:	ec06                	sd	ra,24(sp)
    80003536:	e822                	sd	s0,16(sp)
    80003538:	e426                	sd	s1,8(sp)
    8000353a:	e04a                	sd	s2,0(sp)
    8000353c:	1000                	addi	s0,sp,32
    8000353e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003540:	01050913          	addi	s2,a0,16
    80003544:	854a                	mv	a0,s2
    80003546:	00001097          	auipc	ra,0x1
    8000354a:	42e080e7          	jalr	1070(ra) # 80004974 <holdingsleep>
    8000354e:	c92d                	beqz	a0,800035c0 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003550:	854a                	mv	a0,s2
    80003552:	00001097          	auipc	ra,0x1
    80003556:	3de080e7          	jalr	990(ra) # 80004930 <releasesleep>

  acquire(&bcache.lock);
    8000355a:	00014517          	auipc	a0,0x14
    8000355e:	97e50513          	addi	a0,a0,-1666 # 80016ed8 <bcache>
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	674080e7          	jalr	1652(ra) # 80000bd6 <acquire>
  b->refcnt--;
    8000356a:	40bc                	lw	a5,64(s1)
    8000356c:	37fd                	addiw	a5,a5,-1
    8000356e:	0007871b          	sext.w	a4,a5
    80003572:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003574:	eb05                	bnez	a4,800035a4 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003576:	68bc                	ld	a5,80(s1)
    80003578:	64b8                	ld	a4,72(s1)
    8000357a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000357c:	64bc                	ld	a5,72(s1)
    8000357e:	68b8                	ld	a4,80(s1)
    80003580:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003582:	0001c797          	auipc	a5,0x1c
    80003586:	95678793          	addi	a5,a5,-1706 # 8001eed8 <bcache+0x8000>
    8000358a:	2b87b703          	ld	a4,696(a5)
    8000358e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003590:	0001c717          	auipc	a4,0x1c
    80003594:	bb070713          	addi	a4,a4,-1104 # 8001f140 <bcache+0x8268>
    80003598:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000359a:	2b87b703          	ld	a4,696(a5)
    8000359e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800035a0:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800035a4:	00014517          	auipc	a0,0x14
    800035a8:	93450513          	addi	a0,a0,-1740 # 80016ed8 <bcache>
    800035ac:	ffffd097          	auipc	ra,0xffffd
    800035b0:	6de080e7          	jalr	1758(ra) # 80000c8a <release>
}
    800035b4:	60e2                	ld	ra,24(sp)
    800035b6:	6442                	ld	s0,16(sp)
    800035b8:	64a2                	ld	s1,8(sp)
    800035ba:	6902                	ld	s2,0(sp)
    800035bc:	6105                	addi	sp,sp,32
    800035be:	8082                	ret
    panic("brelse");
    800035c0:	00005517          	auipc	a0,0x5
    800035c4:	05850513          	addi	a0,a0,88 # 80008618 <syscalls+0xf8>
    800035c8:	ffffd097          	auipc	ra,0xffffd
    800035cc:	f78080e7          	jalr	-136(ra) # 80000540 <panic>

00000000800035d0 <bpin>:

void
bpin(struct buf *b) {
    800035d0:	1101                	addi	sp,sp,-32
    800035d2:	ec06                	sd	ra,24(sp)
    800035d4:	e822                	sd	s0,16(sp)
    800035d6:	e426                	sd	s1,8(sp)
    800035d8:	1000                	addi	s0,sp,32
    800035da:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800035dc:	00014517          	auipc	a0,0x14
    800035e0:	8fc50513          	addi	a0,a0,-1796 # 80016ed8 <bcache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	5f2080e7          	jalr	1522(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800035ec:	40bc                	lw	a5,64(s1)
    800035ee:	2785                	addiw	a5,a5,1
    800035f0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800035f2:	00014517          	auipc	a0,0x14
    800035f6:	8e650513          	addi	a0,a0,-1818 # 80016ed8 <bcache>
    800035fa:	ffffd097          	auipc	ra,0xffffd
    800035fe:	690080e7          	jalr	1680(ra) # 80000c8a <release>
}
    80003602:	60e2                	ld	ra,24(sp)
    80003604:	6442                	ld	s0,16(sp)
    80003606:	64a2                	ld	s1,8(sp)
    80003608:	6105                	addi	sp,sp,32
    8000360a:	8082                	ret

000000008000360c <bunpin>:

void
bunpin(struct buf *b) {
    8000360c:	1101                	addi	sp,sp,-32
    8000360e:	ec06                	sd	ra,24(sp)
    80003610:	e822                	sd	s0,16(sp)
    80003612:	e426                	sd	s1,8(sp)
    80003614:	1000                	addi	s0,sp,32
    80003616:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003618:	00014517          	auipc	a0,0x14
    8000361c:	8c050513          	addi	a0,a0,-1856 # 80016ed8 <bcache>
    80003620:	ffffd097          	auipc	ra,0xffffd
    80003624:	5b6080e7          	jalr	1462(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003628:	40bc                	lw	a5,64(s1)
    8000362a:	37fd                	addiw	a5,a5,-1
    8000362c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000362e:	00014517          	auipc	a0,0x14
    80003632:	8aa50513          	addi	a0,a0,-1878 # 80016ed8 <bcache>
    80003636:	ffffd097          	auipc	ra,0xffffd
    8000363a:	654080e7          	jalr	1620(ra) # 80000c8a <release>
}
    8000363e:	60e2                	ld	ra,24(sp)
    80003640:	6442                	ld	s0,16(sp)
    80003642:	64a2                	ld	s1,8(sp)
    80003644:	6105                	addi	sp,sp,32
    80003646:	8082                	ret

0000000080003648 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003648:	1101                	addi	sp,sp,-32
    8000364a:	ec06                	sd	ra,24(sp)
    8000364c:	e822                	sd	s0,16(sp)
    8000364e:	e426                	sd	s1,8(sp)
    80003650:	e04a                	sd	s2,0(sp)
    80003652:	1000                	addi	s0,sp,32
    80003654:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003656:	00d5d59b          	srliw	a1,a1,0xd
    8000365a:	0001c797          	auipc	a5,0x1c
    8000365e:	f5a7a783          	lw	a5,-166(a5) # 8001f5b4 <sb+0x1c>
    80003662:	9dbd                	addw	a1,a1,a5
    80003664:	00000097          	auipc	ra,0x0
    80003668:	d9e080e7          	jalr	-610(ra) # 80003402 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000366c:	0074f713          	andi	a4,s1,7
    80003670:	4785                	li	a5,1
    80003672:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003676:	14ce                	slli	s1,s1,0x33
    80003678:	90d9                	srli	s1,s1,0x36
    8000367a:	00950733          	add	a4,a0,s1
    8000367e:	05874703          	lbu	a4,88(a4)
    80003682:	00e7f6b3          	and	a3,a5,a4
    80003686:	c69d                	beqz	a3,800036b4 <bfree+0x6c>
    80003688:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000368a:	94aa                	add	s1,s1,a0
    8000368c:	fff7c793          	not	a5,a5
    80003690:	8f7d                	and	a4,a4,a5
    80003692:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	126080e7          	jalr	294(ra) # 800047bc <log_write>
  brelse(bp);
    8000369e:	854a                	mv	a0,s2
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	e92080e7          	jalr	-366(ra) # 80003532 <brelse>
}
    800036a8:	60e2                	ld	ra,24(sp)
    800036aa:	6442                	ld	s0,16(sp)
    800036ac:	64a2                	ld	s1,8(sp)
    800036ae:	6902                	ld	s2,0(sp)
    800036b0:	6105                	addi	sp,sp,32
    800036b2:	8082                	ret
    panic("freeing free block");
    800036b4:	00005517          	auipc	a0,0x5
    800036b8:	f6c50513          	addi	a0,a0,-148 # 80008620 <syscalls+0x100>
    800036bc:	ffffd097          	auipc	ra,0xffffd
    800036c0:	e84080e7          	jalr	-380(ra) # 80000540 <panic>

00000000800036c4 <balloc>:
{
    800036c4:	711d                	addi	sp,sp,-96
    800036c6:	ec86                	sd	ra,88(sp)
    800036c8:	e8a2                	sd	s0,80(sp)
    800036ca:	e4a6                	sd	s1,72(sp)
    800036cc:	e0ca                	sd	s2,64(sp)
    800036ce:	fc4e                	sd	s3,56(sp)
    800036d0:	f852                	sd	s4,48(sp)
    800036d2:	f456                	sd	s5,40(sp)
    800036d4:	f05a                	sd	s6,32(sp)
    800036d6:	ec5e                	sd	s7,24(sp)
    800036d8:	e862                	sd	s8,16(sp)
    800036da:	e466                	sd	s9,8(sp)
    800036dc:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800036de:	0001c797          	auipc	a5,0x1c
    800036e2:	ebe7a783          	lw	a5,-322(a5) # 8001f59c <sb+0x4>
    800036e6:	cff5                	beqz	a5,800037e2 <balloc+0x11e>
    800036e8:	8baa                	mv	s7,a0
    800036ea:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800036ec:	0001cb17          	auipc	s6,0x1c
    800036f0:	eacb0b13          	addi	s6,s6,-340 # 8001f598 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036f4:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800036f6:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036f8:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800036fa:	6c89                	lui	s9,0x2
    800036fc:	a061                	j	80003784 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800036fe:	97ca                	add	a5,a5,s2
    80003700:	8e55                	or	a2,a2,a3
    80003702:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80003706:	854a                	mv	a0,s2
    80003708:	00001097          	auipc	ra,0x1
    8000370c:	0b4080e7          	jalr	180(ra) # 800047bc <log_write>
        brelse(bp);
    80003710:	854a                	mv	a0,s2
    80003712:	00000097          	auipc	ra,0x0
    80003716:	e20080e7          	jalr	-480(ra) # 80003532 <brelse>
  bp = bread(dev, bno);
    8000371a:	85a6                	mv	a1,s1
    8000371c:	855e                	mv	a0,s7
    8000371e:	00000097          	auipc	ra,0x0
    80003722:	ce4080e7          	jalr	-796(ra) # 80003402 <bread>
    80003726:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003728:	40000613          	li	a2,1024
    8000372c:	4581                	li	a1,0
    8000372e:	05850513          	addi	a0,a0,88
    80003732:	ffffd097          	auipc	ra,0xffffd
    80003736:	5a0080e7          	jalr	1440(ra) # 80000cd2 <memset>
  log_write(bp);
    8000373a:	854a                	mv	a0,s2
    8000373c:	00001097          	auipc	ra,0x1
    80003740:	080080e7          	jalr	128(ra) # 800047bc <log_write>
  brelse(bp);
    80003744:	854a                	mv	a0,s2
    80003746:	00000097          	auipc	ra,0x0
    8000374a:	dec080e7          	jalr	-532(ra) # 80003532 <brelse>
}
    8000374e:	8526                	mv	a0,s1
    80003750:	60e6                	ld	ra,88(sp)
    80003752:	6446                	ld	s0,80(sp)
    80003754:	64a6                	ld	s1,72(sp)
    80003756:	6906                	ld	s2,64(sp)
    80003758:	79e2                	ld	s3,56(sp)
    8000375a:	7a42                	ld	s4,48(sp)
    8000375c:	7aa2                	ld	s5,40(sp)
    8000375e:	7b02                	ld	s6,32(sp)
    80003760:	6be2                	ld	s7,24(sp)
    80003762:	6c42                	ld	s8,16(sp)
    80003764:	6ca2                	ld	s9,8(sp)
    80003766:	6125                	addi	sp,sp,96
    80003768:	8082                	ret
    brelse(bp);
    8000376a:	854a                	mv	a0,s2
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	dc6080e7          	jalr	-570(ra) # 80003532 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003774:	015c87bb          	addw	a5,s9,s5
    80003778:	00078a9b          	sext.w	s5,a5
    8000377c:	004b2703          	lw	a4,4(s6)
    80003780:	06eaf163          	bgeu	s5,a4,800037e2 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    80003784:	41fad79b          	sraiw	a5,s5,0x1f
    80003788:	0137d79b          	srliw	a5,a5,0x13
    8000378c:	015787bb          	addw	a5,a5,s5
    80003790:	40d7d79b          	sraiw	a5,a5,0xd
    80003794:	01cb2583          	lw	a1,28(s6)
    80003798:	9dbd                	addw	a1,a1,a5
    8000379a:	855e                	mv	a0,s7
    8000379c:	00000097          	auipc	ra,0x0
    800037a0:	c66080e7          	jalr	-922(ra) # 80003402 <bread>
    800037a4:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037a6:	004b2503          	lw	a0,4(s6)
    800037aa:	000a849b          	sext.w	s1,s5
    800037ae:	8762                	mv	a4,s8
    800037b0:	faa4fde3          	bgeu	s1,a0,8000376a <balloc+0xa6>
      m = 1 << (bi % 8);
    800037b4:	00777693          	andi	a3,a4,7
    800037b8:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800037bc:	41f7579b          	sraiw	a5,a4,0x1f
    800037c0:	01d7d79b          	srliw	a5,a5,0x1d
    800037c4:	9fb9                	addw	a5,a5,a4
    800037c6:	4037d79b          	sraiw	a5,a5,0x3
    800037ca:	00f90633          	add	a2,s2,a5
    800037ce:	05864603          	lbu	a2,88(a2)
    800037d2:	00c6f5b3          	and	a1,a3,a2
    800037d6:	d585                	beqz	a1,800036fe <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800037d8:	2705                	addiw	a4,a4,1
    800037da:	2485                	addiw	s1,s1,1
    800037dc:	fd471ae3          	bne	a4,s4,800037b0 <balloc+0xec>
    800037e0:	b769                	j	8000376a <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800037e2:	00005517          	auipc	a0,0x5
    800037e6:	e5650513          	addi	a0,a0,-426 # 80008638 <syscalls+0x118>
    800037ea:	ffffd097          	auipc	ra,0xffffd
    800037ee:	da0080e7          	jalr	-608(ra) # 8000058a <printf>
  return 0;
    800037f2:	4481                	li	s1,0
    800037f4:	bfa9                	j	8000374e <balloc+0x8a>

00000000800037f6 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800037f6:	7179                	addi	sp,sp,-48
    800037f8:	f406                	sd	ra,40(sp)
    800037fa:	f022                	sd	s0,32(sp)
    800037fc:	ec26                	sd	s1,24(sp)
    800037fe:	e84a                	sd	s2,16(sp)
    80003800:	e44e                	sd	s3,8(sp)
    80003802:	e052                	sd	s4,0(sp)
    80003804:	1800                	addi	s0,sp,48
    80003806:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003808:	47ad                	li	a5,11
    8000380a:	02b7e863          	bltu	a5,a1,8000383a <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000380e:	02059793          	slli	a5,a1,0x20
    80003812:	01e7d593          	srli	a1,a5,0x1e
    80003816:	00b504b3          	add	s1,a0,a1
    8000381a:	0504a903          	lw	s2,80(s1)
    8000381e:	06091e63          	bnez	s2,8000389a <bmap+0xa4>
      addr = balloc(ip->dev);
    80003822:	4108                	lw	a0,0(a0)
    80003824:	00000097          	auipc	ra,0x0
    80003828:	ea0080e7          	jalr	-352(ra) # 800036c4 <balloc>
    8000382c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003830:	06090563          	beqz	s2,8000389a <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80003834:	0524a823          	sw	s2,80(s1)
    80003838:	a08d                	j	8000389a <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    8000383a:	ff45849b          	addiw	s1,a1,-12
    8000383e:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003842:	0ff00793          	li	a5,255
    80003846:	08e7e563          	bltu	a5,a4,800038d0 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    8000384a:	08052903          	lw	s2,128(a0)
    8000384e:	00091d63          	bnez	s2,80003868 <bmap+0x72>
      addr = balloc(ip->dev);
    80003852:	4108                	lw	a0,0(a0)
    80003854:	00000097          	auipc	ra,0x0
    80003858:	e70080e7          	jalr	-400(ra) # 800036c4 <balloc>
    8000385c:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003860:	02090d63          	beqz	s2,8000389a <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003864:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003868:	85ca                	mv	a1,s2
    8000386a:	0009a503          	lw	a0,0(s3)
    8000386e:	00000097          	auipc	ra,0x0
    80003872:	b94080e7          	jalr	-1132(ra) # 80003402 <bread>
    80003876:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003878:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    8000387c:	02049713          	slli	a4,s1,0x20
    80003880:	01e75593          	srli	a1,a4,0x1e
    80003884:	00b784b3          	add	s1,a5,a1
    80003888:	0004a903          	lw	s2,0(s1)
    8000388c:	02090063          	beqz	s2,800038ac <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003890:	8552                	mv	a0,s4
    80003892:	00000097          	auipc	ra,0x0
    80003896:	ca0080e7          	jalr	-864(ra) # 80003532 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000389a:	854a                	mv	a0,s2
    8000389c:	70a2                	ld	ra,40(sp)
    8000389e:	7402                	ld	s0,32(sp)
    800038a0:	64e2                	ld	s1,24(sp)
    800038a2:	6942                	ld	s2,16(sp)
    800038a4:	69a2                	ld	s3,8(sp)
    800038a6:	6a02                	ld	s4,0(sp)
    800038a8:	6145                	addi	sp,sp,48
    800038aa:	8082                	ret
      addr = balloc(ip->dev);
    800038ac:	0009a503          	lw	a0,0(s3)
    800038b0:	00000097          	auipc	ra,0x0
    800038b4:	e14080e7          	jalr	-492(ra) # 800036c4 <balloc>
    800038b8:	0005091b          	sext.w	s2,a0
      if(addr){
    800038bc:	fc090ae3          	beqz	s2,80003890 <bmap+0x9a>
        a[bn] = addr;
    800038c0:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800038c4:	8552                	mv	a0,s4
    800038c6:	00001097          	auipc	ra,0x1
    800038ca:	ef6080e7          	jalr	-266(ra) # 800047bc <log_write>
    800038ce:	b7c9                	j	80003890 <bmap+0x9a>
  panic("bmap: out of range");
    800038d0:	00005517          	auipc	a0,0x5
    800038d4:	d8050513          	addi	a0,a0,-640 # 80008650 <syscalls+0x130>
    800038d8:	ffffd097          	auipc	ra,0xffffd
    800038dc:	c68080e7          	jalr	-920(ra) # 80000540 <panic>

00000000800038e0 <iget>:
{
    800038e0:	7179                	addi	sp,sp,-48
    800038e2:	f406                	sd	ra,40(sp)
    800038e4:	f022                	sd	s0,32(sp)
    800038e6:	ec26                	sd	s1,24(sp)
    800038e8:	e84a                	sd	s2,16(sp)
    800038ea:	e44e                	sd	s3,8(sp)
    800038ec:	e052                	sd	s4,0(sp)
    800038ee:	1800                	addi	s0,sp,48
    800038f0:	89aa                	mv	s3,a0
    800038f2:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800038f4:	0001c517          	auipc	a0,0x1c
    800038f8:	cc450513          	addi	a0,a0,-828 # 8001f5b8 <itable>
    800038fc:	ffffd097          	auipc	ra,0xffffd
    80003900:	2da080e7          	jalr	730(ra) # 80000bd6 <acquire>
  empty = 0;
    80003904:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003906:	0001c497          	auipc	s1,0x1c
    8000390a:	cca48493          	addi	s1,s1,-822 # 8001f5d0 <itable+0x18>
    8000390e:	0001d697          	auipc	a3,0x1d
    80003912:	75268693          	addi	a3,a3,1874 # 80021060 <log>
    80003916:	a039                	j	80003924 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003918:	02090b63          	beqz	s2,8000394e <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000391c:	08848493          	addi	s1,s1,136
    80003920:	02d48a63          	beq	s1,a3,80003954 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003924:	449c                	lw	a5,8(s1)
    80003926:	fef059e3          	blez	a5,80003918 <iget+0x38>
    8000392a:	4098                	lw	a4,0(s1)
    8000392c:	ff3716e3          	bne	a4,s3,80003918 <iget+0x38>
    80003930:	40d8                	lw	a4,4(s1)
    80003932:	ff4713e3          	bne	a4,s4,80003918 <iget+0x38>
      ip->ref++;
    80003936:	2785                	addiw	a5,a5,1
    80003938:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000393a:	0001c517          	auipc	a0,0x1c
    8000393e:	c7e50513          	addi	a0,a0,-898 # 8001f5b8 <itable>
    80003942:	ffffd097          	auipc	ra,0xffffd
    80003946:	348080e7          	jalr	840(ra) # 80000c8a <release>
      return ip;
    8000394a:	8926                	mv	s2,s1
    8000394c:	a03d                	j	8000397a <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000394e:	f7f9                	bnez	a5,8000391c <iget+0x3c>
    80003950:	8926                	mv	s2,s1
    80003952:	b7e9                	j	8000391c <iget+0x3c>
  if(empty == 0)
    80003954:	02090c63          	beqz	s2,8000398c <iget+0xac>
  ip->dev = dev;
    80003958:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000395c:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003960:	4785                	li	a5,1
    80003962:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003966:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    8000396a:	0001c517          	auipc	a0,0x1c
    8000396e:	c4e50513          	addi	a0,a0,-946 # 8001f5b8 <itable>
    80003972:	ffffd097          	auipc	ra,0xffffd
    80003976:	318080e7          	jalr	792(ra) # 80000c8a <release>
}
    8000397a:	854a                	mv	a0,s2
    8000397c:	70a2                	ld	ra,40(sp)
    8000397e:	7402                	ld	s0,32(sp)
    80003980:	64e2                	ld	s1,24(sp)
    80003982:	6942                	ld	s2,16(sp)
    80003984:	69a2                	ld	s3,8(sp)
    80003986:	6a02                	ld	s4,0(sp)
    80003988:	6145                	addi	sp,sp,48
    8000398a:	8082                	ret
    panic("iget: no inodes");
    8000398c:	00005517          	auipc	a0,0x5
    80003990:	cdc50513          	addi	a0,a0,-804 # 80008668 <syscalls+0x148>
    80003994:	ffffd097          	auipc	ra,0xffffd
    80003998:	bac080e7          	jalr	-1108(ra) # 80000540 <panic>

000000008000399c <fsinit>:
fsinit(int dev) {
    8000399c:	7179                	addi	sp,sp,-48
    8000399e:	f406                	sd	ra,40(sp)
    800039a0:	f022                	sd	s0,32(sp)
    800039a2:	ec26                	sd	s1,24(sp)
    800039a4:	e84a                	sd	s2,16(sp)
    800039a6:	e44e                	sd	s3,8(sp)
    800039a8:	1800                	addi	s0,sp,48
    800039aa:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800039ac:	4585                	li	a1,1
    800039ae:	00000097          	auipc	ra,0x0
    800039b2:	a54080e7          	jalr	-1452(ra) # 80003402 <bread>
    800039b6:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800039b8:	0001c997          	auipc	s3,0x1c
    800039bc:	be098993          	addi	s3,s3,-1056 # 8001f598 <sb>
    800039c0:	02000613          	li	a2,32
    800039c4:	05850593          	addi	a1,a0,88
    800039c8:	854e                	mv	a0,s3
    800039ca:	ffffd097          	auipc	ra,0xffffd
    800039ce:	364080e7          	jalr	868(ra) # 80000d2e <memmove>
  brelse(bp);
    800039d2:	8526                	mv	a0,s1
    800039d4:	00000097          	auipc	ra,0x0
    800039d8:	b5e080e7          	jalr	-1186(ra) # 80003532 <brelse>
  if(sb.magic != FSMAGIC)
    800039dc:	0009a703          	lw	a4,0(s3)
    800039e0:	102037b7          	lui	a5,0x10203
    800039e4:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800039e8:	02f71263          	bne	a4,a5,80003a0c <fsinit+0x70>
  initlog(dev, &sb);
    800039ec:	0001c597          	auipc	a1,0x1c
    800039f0:	bac58593          	addi	a1,a1,-1108 # 8001f598 <sb>
    800039f4:	854a                	mv	a0,s2
    800039f6:	00001097          	auipc	ra,0x1
    800039fa:	b4a080e7          	jalr	-1206(ra) # 80004540 <initlog>
}
    800039fe:	70a2                	ld	ra,40(sp)
    80003a00:	7402                	ld	s0,32(sp)
    80003a02:	64e2                	ld	s1,24(sp)
    80003a04:	6942                	ld	s2,16(sp)
    80003a06:	69a2                	ld	s3,8(sp)
    80003a08:	6145                	addi	sp,sp,48
    80003a0a:	8082                	ret
    panic("invalid file system");
    80003a0c:	00005517          	auipc	a0,0x5
    80003a10:	c6c50513          	addi	a0,a0,-916 # 80008678 <syscalls+0x158>
    80003a14:	ffffd097          	auipc	ra,0xffffd
    80003a18:	b2c080e7          	jalr	-1236(ra) # 80000540 <panic>

0000000080003a1c <iinit>:
{
    80003a1c:	7179                	addi	sp,sp,-48
    80003a1e:	f406                	sd	ra,40(sp)
    80003a20:	f022                	sd	s0,32(sp)
    80003a22:	ec26                	sd	s1,24(sp)
    80003a24:	e84a                	sd	s2,16(sp)
    80003a26:	e44e                	sd	s3,8(sp)
    80003a28:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003a2a:	00005597          	auipc	a1,0x5
    80003a2e:	c6658593          	addi	a1,a1,-922 # 80008690 <syscalls+0x170>
    80003a32:	0001c517          	auipc	a0,0x1c
    80003a36:	b8650513          	addi	a0,a0,-1146 # 8001f5b8 <itable>
    80003a3a:	ffffd097          	auipc	ra,0xffffd
    80003a3e:	10c080e7          	jalr	268(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003a42:	0001c497          	auipc	s1,0x1c
    80003a46:	b9e48493          	addi	s1,s1,-1122 # 8001f5e0 <itable+0x28>
    80003a4a:	0001d997          	auipc	s3,0x1d
    80003a4e:	62698993          	addi	s3,s3,1574 # 80021070 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003a52:	00005917          	auipc	s2,0x5
    80003a56:	c4690913          	addi	s2,s2,-954 # 80008698 <syscalls+0x178>
    80003a5a:	85ca                	mv	a1,s2
    80003a5c:	8526                	mv	a0,s1
    80003a5e:	00001097          	auipc	ra,0x1
    80003a62:	e42080e7          	jalr	-446(ra) # 800048a0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003a66:	08848493          	addi	s1,s1,136
    80003a6a:	ff3498e3          	bne	s1,s3,80003a5a <iinit+0x3e>
}
    80003a6e:	70a2                	ld	ra,40(sp)
    80003a70:	7402                	ld	s0,32(sp)
    80003a72:	64e2                	ld	s1,24(sp)
    80003a74:	6942                	ld	s2,16(sp)
    80003a76:	69a2                	ld	s3,8(sp)
    80003a78:	6145                	addi	sp,sp,48
    80003a7a:	8082                	ret

0000000080003a7c <ialloc>:
{
    80003a7c:	715d                	addi	sp,sp,-80
    80003a7e:	e486                	sd	ra,72(sp)
    80003a80:	e0a2                	sd	s0,64(sp)
    80003a82:	fc26                	sd	s1,56(sp)
    80003a84:	f84a                	sd	s2,48(sp)
    80003a86:	f44e                	sd	s3,40(sp)
    80003a88:	f052                	sd	s4,32(sp)
    80003a8a:	ec56                	sd	s5,24(sp)
    80003a8c:	e85a                	sd	s6,16(sp)
    80003a8e:	e45e                	sd	s7,8(sp)
    80003a90:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a92:	0001c717          	auipc	a4,0x1c
    80003a96:	b1272703          	lw	a4,-1262(a4) # 8001f5a4 <sb+0xc>
    80003a9a:	4785                	li	a5,1
    80003a9c:	04e7fa63          	bgeu	a5,a4,80003af0 <ialloc+0x74>
    80003aa0:	8aaa                	mv	s5,a0
    80003aa2:	8bae                	mv	s7,a1
    80003aa4:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003aa6:	0001ca17          	auipc	s4,0x1c
    80003aaa:	af2a0a13          	addi	s4,s4,-1294 # 8001f598 <sb>
    80003aae:	00048b1b          	sext.w	s6,s1
    80003ab2:	0044d593          	srli	a1,s1,0x4
    80003ab6:	018a2783          	lw	a5,24(s4)
    80003aba:	9dbd                	addw	a1,a1,a5
    80003abc:	8556                	mv	a0,s5
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	944080e7          	jalr	-1724(ra) # 80003402 <bread>
    80003ac6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003ac8:	05850993          	addi	s3,a0,88
    80003acc:	00f4f793          	andi	a5,s1,15
    80003ad0:	079a                	slli	a5,a5,0x6
    80003ad2:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003ad4:	00099783          	lh	a5,0(s3)
    80003ad8:	c3a1                	beqz	a5,80003b18 <ialloc+0x9c>
    brelse(bp);
    80003ada:	00000097          	auipc	ra,0x0
    80003ade:	a58080e7          	jalr	-1448(ra) # 80003532 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003ae2:	0485                	addi	s1,s1,1
    80003ae4:	00ca2703          	lw	a4,12(s4)
    80003ae8:	0004879b          	sext.w	a5,s1
    80003aec:	fce7e1e3          	bltu	a5,a4,80003aae <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003af0:	00005517          	auipc	a0,0x5
    80003af4:	bb050513          	addi	a0,a0,-1104 # 800086a0 <syscalls+0x180>
    80003af8:	ffffd097          	auipc	ra,0xffffd
    80003afc:	a92080e7          	jalr	-1390(ra) # 8000058a <printf>
  return 0;
    80003b00:	4501                	li	a0,0
}
    80003b02:	60a6                	ld	ra,72(sp)
    80003b04:	6406                	ld	s0,64(sp)
    80003b06:	74e2                	ld	s1,56(sp)
    80003b08:	7942                	ld	s2,48(sp)
    80003b0a:	79a2                	ld	s3,40(sp)
    80003b0c:	7a02                	ld	s4,32(sp)
    80003b0e:	6ae2                	ld	s5,24(sp)
    80003b10:	6b42                	ld	s6,16(sp)
    80003b12:	6ba2                	ld	s7,8(sp)
    80003b14:	6161                	addi	sp,sp,80
    80003b16:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003b18:	04000613          	li	a2,64
    80003b1c:	4581                	li	a1,0
    80003b1e:	854e                	mv	a0,s3
    80003b20:	ffffd097          	auipc	ra,0xffffd
    80003b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
      dip->type = type;
    80003b28:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003b2c:	854a                	mv	a0,s2
    80003b2e:	00001097          	auipc	ra,0x1
    80003b32:	c8e080e7          	jalr	-882(ra) # 800047bc <log_write>
      brelse(bp);
    80003b36:	854a                	mv	a0,s2
    80003b38:	00000097          	auipc	ra,0x0
    80003b3c:	9fa080e7          	jalr	-1542(ra) # 80003532 <brelse>
      return iget(dev, inum);
    80003b40:	85da                	mv	a1,s6
    80003b42:	8556                	mv	a0,s5
    80003b44:	00000097          	auipc	ra,0x0
    80003b48:	d9c080e7          	jalr	-612(ra) # 800038e0 <iget>
    80003b4c:	bf5d                	j	80003b02 <ialloc+0x86>

0000000080003b4e <iupdate>:
{
    80003b4e:	1101                	addi	sp,sp,-32
    80003b50:	ec06                	sd	ra,24(sp)
    80003b52:	e822                	sd	s0,16(sp)
    80003b54:	e426                	sd	s1,8(sp)
    80003b56:	e04a                	sd	s2,0(sp)
    80003b58:	1000                	addi	s0,sp,32
    80003b5a:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b5c:	415c                	lw	a5,4(a0)
    80003b5e:	0047d79b          	srliw	a5,a5,0x4
    80003b62:	0001c597          	auipc	a1,0x1c
    80003b66:	a4e5a583          	lw	a1,-1458(a1) # 8001f5b0 <sb+0x18>
    80003b6a:	9dbd                	addw	a1,a1,a5
    80003b6c:	4108                	lw	a0,0(a0)
    80003b6e:	00000097          	auipc	ra,0x0
    80003b72:	894080e7          	jalr	-1900(ra) # 80003402 <bread>
    80003b76:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b78:	05850793          	addi	a5,a0,88
    80003b7c:	40d8                	lw	a4,4(s1)
    80003b7e:	8b3d                	andi	a4,a4,15
    80003b80:	071a                	slli	a4,a4,0x6
    80003b82:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003b84:	04449703          	lh	a4,68(s1)
    80003b88:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003b8c:	04649703          	lh	a4,70(s1)
    80003b90:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003b94:	04849703          	lh	a4,72(s1)
    80003b98:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003b9c:	04a49703          	lh	a4,74(s1)
    80003ba0:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003ba4:	44f8                	lw	a4,76(s1)
    80003ba6:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003ba8:	03400613          	li	a2,52
    80003bac:	05048593          	addi	a1,s1,80
    80003bb0:	00c78513          	addi	a0,a5,12
    80003bb4:	ffffd097          	auipc	ra,0xffffd
    80003bb8:	17a080e7          	jalr	378(ra) # 80000d2e <memmove>
  log_write(bp);
    80003bbc:	854a                	mv	a0,s2
    80003bbe:	00001097          	auipc	ra,0x1
    80003bc2:	bfe080e7          	jalr	-1026(ra) # 800047bc <log_write>
  brelse(bp);
    80003bc6:	854a                	mv	a0,s2
    80003bc8:	00000097          	auipc	ra,0x0
    80003bcc:	96a080e7          	jalr	-1686(ra) # 80003532 <brelse>
}
    80003bd0:	60e2                	ld	ra,24(sp)
    80003bd2:	6442                	ld	s0,16(sp)
    80003bd4:	64a2                	ld	s1,8(sp)
    80003bd6:	6902                	ld	s2,0(sp)
    80003bd8:	6105                	addi	sp,sp,32
    80003bda:	8082                	ret

0000000080003bdc <idup>:
{
    80003bdc:	1101                	addi	sp,sp,-32
    80003bde:	ec06                	sd	ra,24(sp)
    80003be0:	e822                	sd	s0,16(sp)
    80003be2:	e426                	sd	s1,8(sp)
    80003be4:	1000                	addi	s0,sp,32
    80003be6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003be8:	0001c517          	auipc	a0,0x1c
    80003bec:	9d050513          	addi	a0,a0,-1584 # 8001f5b8 <itable>
    80003bf0:	ffffd097          	auipc	ra,0xffffd
    80003bf4:	fe6080e7          	jalr	-26(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003bf8:	449c                	lw	a5,8(s1)
    80003bfa:	2785                	addiw	a5,a5,1
    80003bfc:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003bfe:	0001c517          	auipc	a0,0x1c
    80003c02:	9ba50513          	addi	a0,a0,-1606 # 8001f5b8 <itable>
    80003c06:	ffffd097          	auipc	ra,0xffffd
    80003c0a:	084080e7          	jalr	132(ra) # 80000c8a <release>
}
    80003c0e:	8526                	mv	a0,s1
    80003c10:	60e2                	ld	ra,24(sp)
    80003c12:	6442                	ld	s0,16(sp)
    80003c14:	64a2                	ld	s1,8(sp)
    80003c16:	6105                	addi	sp,sp,32
    80003c18:	8082                	ret

0000000080003c1a <ilock>:
{
    80003c1a:	1101                	addi	sp,sp,-32
    80003c1c:	ec06                	sd	ra,24(sp)
    80003c1e:	e822                	sd	s0,16(sp)
    80003c20:	e426                	sd	s1,8(sp)
    80003c22:	e04a                	sd	s2,0(sp)
    80003c24:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003c26:	c115                	beqz	a0,80003c4a <ilock+0x30>
    80003c28:	84aa                	mv	s1,a0
    80003c2a:	451c                	lw	a5,8(a0)
    80003c2c:	00f05f63          	blez	a5,80003c4a <ilock+0x30>
  acquiresleep(&ip->lock);
    80003c30:	0541                	addi	a0,a0,16
    80003c32:	00001097          	auipc	ra,0x1
    80003c36:	ca8080e7          	jalr	-856(ra) # 800048da <acquiresleep>
  if(ip->valid == 0){
    80003c3a:	40bc                	lw	a5,64(s1)
    80003c3c:	cf99                	beqz	a5,80003c5a <ilock+0x40>
}
    80003c3e:	60e2                	ld	ra,24(sp)
    80003c40:	6442                	ld	s0,16(sp)
    80003c42:	64a2                	ld	s1,8(sp)
    80003c44:	6902                	ld	s2,0(sp)
    80003c46:	6105                	addi	sp,sp,32
    80003c48:	8082                	ret
    panic("ilock");
    80003c4a:	00005517          	auipc	a0,0x5
    80003c4e:	a6e50513          	addi	a0,a0,-1426 # 800086b8 <syscalls+0x198>
    80003c52:	ffffd097          	auipc	ra,0xffffd
    80003c56:	8ee080e7          	jalr	-1810(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003c5a:	40dc                	lw	a5,4(s1)
    80003c5c:	0047d79b          	srliw	a5,a5,0x4
    80003c60:	0001c597          	auipc	a1,0x1c
    80003c64:	9505a583          	lw	a1,-1712(a1) # 8001f5b0 <sb+0x18>
    80003c68:	9dbd                	addw	a1,a1,a5
    80003c6a:	4088                	lw	a0,0(s1)
    80003c6c:	fffff097          	auipc	ra,0xfffff
    80003c70:	796080e7          	jalr	1942(ra) # 80003402 <bread>
    80003c74:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003c76:	05850593          	addi	a1,a0,88
    80003c7a:	40dc                	lw	a5,4(s1)
    80003c7c:	8bbd                	andi	a5,a5,15
    80003c7e:	079a                	slli	a5,a5,0x6
    80003c80:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003c82:	00059783          	lh	a5,0(a1)
    80003c86:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003c8a:	00259783          	lh	a5,2(a1)
    80003c8e:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003c92:	00459783          	lh	a5,4(a1)
    80003c96:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003c9a:	00659783          	lh	a5,6(a1)
    80003c9e:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003ca2:	459c                	lw	a5,8(a1)
    80003ca4:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003ca6:	03400613          	li	a2,52
    80003caa:	05b1                	addi	a1,a1,12
    80003cac:	05048513          	addi	a0,s1,80
    80003cb0:	ffffd097          	auipc	ra,0xffffd
    80003cb4:	07e080e7          	jalr	126(ra) # 80000d2e <memmove>
    brelse(bp);
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	878080e7          	jalr	-1928(ra) # 80003532 <brelse>
    ip->valid = 1;
    80003cc2:	4785                	li	a5,1
    80003cc4:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003cc6:	04449783          	lh	a5,68(s1)
    80003cca:	fbb5                	bnez	a5,80003c3e <ilock+0x24>
      panic("ilock: no type");
    80003ccc:	00005517          	auipc	a0,0x5
    80003cd0:	9f450513          	addi	a0,a0,-1548 # 800086c0 <syscalls+0x1a0>
    80003cd4:	ffffd097          	auipc	ra,0xffffd
    80003cd8:	86c080e7          	jalr	-1940(ra) # 80000540 <panic>

0000000080003cdc <iunlock>:
{
    80003cdc:	1101                	addi	sp,sp,-32
    80003cde:	ec06                	sd	ra,24(sp)
    80003ce0:	e822                	sd	s0,16(sp)
    80003ce2:	e426                	sd	s1,8(sp)
    80003ce4:	e04a                	sd	s2,0(sp)
    80003ce6:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003ce8:	c905                	beqz	a0,80003d18 <iunlock+0x3c>
    80003cea:	84aa                	mv	s1,a0
    80003cec:	01050913          	addi	s2,a0,16
    80003cf0:	854a                	mv	a0,s2
    80003cf2:	00001097          	auipc	ra,0x1
    80003cf6:	c82080e7          	jalr	-894(ra) # 80004974 <holdingsleep>
    80003cfa:	cd19                	beqz	a0,80003d18 <iunlock+0x3c>
    80003cfc:	449c                	lw	a5,8(s1)
    80003cfe:	00f05d63          	blez	a5,80003d18 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003d02:	854a                	mv	a0,s2
    80003d04:	00001097          	auipc	ra,0x1
    80003d08:	c2c080e7          	jalr	-980(ra) # 80004930 <releasesleep>
}
    80003d0c:	60e2                	ld	ra,24(sp)
    80003d0e:	6442                	ld	s0,16(sp)
    80003d10:	64a2                	ld	s1,8(sp)
    80003d12:	6902                	ld	s2,0(sp)
    80003d14:	6105                	addi	sp,sp,32
    80003d16:	8082                	ret
    panic("iunlock");
    80003d18:	00005517          	auipc	a0,0x5
    80003d1c:	9b850513          	addi	a0,a0,-1608 # 800086d0 <syscalls+0x1b0>
    80003d20:	ffffd097          	auipc	ra,0xffffd
    80003d24:	820080e7          	jalr	-2016(ra) # 80000540 <panic>

0000000080003d28 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003d28:	7179                	addi	sp,sp,-48
    80003d2a:	f406                	sd	ra,40(sp)
    80003d2c:	f022                	sd	s0,32(sp)
    80003d2e:	ec26                	sd	s1,24(sp)
    80003d30:	e84a                	sd	s2,16(sp)
    80003d32:	e44e                	sd	s3,8(sp)
    80003d34:	e052                	sd	s4,0(sp)
    80003d36:	1800                	addi	s0,sp,48
    80003d38:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003d3a:	05050493          	addi	s1,a0,80
    80003d3e:	08050913          	addi	s2,a0,128
    80003d42:	a021                	j	80003d4a <itrunc+0x22>
    80003d44:	0491                	addi	s1,s1,4
    80003d46:	01248d63          	beq	s1,s2,80003d60 <itrunc+0x38>
    if(ip->addrs[i]){
    80003d4a:	408c                	lw	a1,0(s1)
    80003d4c:	dde5                	beqz	a1,80003d44 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003d4e:	0009a503          	lw	a0,0(s3)
    80003d52:	00000097          	auipc	ra,0x0
    80003d56:	8f6080e7          	jalr	-1802(ra) # 80003648 <bfree>
      ip->addrs[i] = 0;
    80003d5a:	0004a023          	sw	zero,0(s1)
    80003d5e:	b7dd                	j	80003d44 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003d60:	0809a583          	lw	a1,128(s3)
    80003d64:	e185                	bnez	a1,80003d84 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003d66:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003d6a:	854e                	mv	a0,s3
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	de2080e7          	jalr	-542(ra) # 80003b4e <iupdate>
}
    80003d74:	70a2                	ld	ra,40(sp)
    80003d76:	7402                	ld	s0,32(sp)
    80003d78:	64e2                	ld	s1,24(sp)
    80003d7a:	6942                	ld	s2,16(sp)
    80003d7c:	69a2                	ld	s3,8(sp)
    80003d7e:	6a02                	ld	s4,0(sp)
    80003d80:	6145                	addi	sp,sp,48
    80003d82:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003d84:	0009a503          	lw	a0,0(s3)
    80003d88:	fffff097          	auipc	ra,0xfffff
    80003d8c:	67a080e7          	jalr	1658(ra) # 80003402 <bread>
    80003d90:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d92:	05850493          	addi	s1,a0,88
    80003d96:	45850913          	addi	s2,a0,1112
    80003d9a:	a021                	j	80003da2 <itrunc+0x7a>
    80003d9c:	0491                	addi	s1,s1,4
    80003d9e:	01248b63          	beq	s1,s2,80003db4 <itrunc+0x8c>
      if(a[j])
    80003da2:	408c                	lw	a1,0(s1)
    80003da4:	dde5                	beqz	a1,80003d9c <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003da6:	0009a503          	lw	a0,0(s3)
    80003daa:	00000097          	auipc	ra,0x0
    80003dae:	89e080e7          	jalr	-1890(ra) # 80003648 <bfree>
    80003db2:	b7ed                	j	80003d9c <itrunc+0x74>
    brelse(bp);
    80003db4:	8552                	mv	a0,s4
    80003db6:	fffff097          	auipc	ra,0xfffff
    80003dba:	77c080e7          	jalr	1916(ra) # 80003532 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003dbe:	0809a583          	lw	a1,128(s3)
    80003dc2:	0009a503          	lw	a0,0(s3)
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	882080e7          	jalr	-1918(ra) # 80003648 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003dce:	0809a023          	sw	zero,128(s3)
    80003dd2:	bf51                	j	80003d66 <itrunc+0x3e>

0000000080003dd4 <iput>:
{
    80003dd4:	1101                	addi	sp,sp,-32
    80003dd6:	ec06                	sd	ra,24(sp)
    80003dd8:	e822                	sd	s0,16(sp)
    80003dda:	e426                	sd	s1,8(sp)
    80003ddc:	e04a                	sd	s2,0(sp)
    80003dde:	1000                	addi	s0,sp,32
    80003de0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003de2:	0001b517          	auipc	a0,0x1b
    80003de6:	7d650513          	addi	a0,a0,2006 # 8001f5b8 <itable>
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	dec080e7          	jalr	-532(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003df2:	4498                	lw	a4,8(s1)
    80003df4:	4785                	li	a5,1
    80003df6:	02f70363          	beq	a4,a5,80003e1c <iput+0x48>
  ip->ref--;
    80003dfa:	449c                	lw	a5,8(s1)
    80003dfc:	37fd                	addiw	a5,a5,-1
    80003dfe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003e00:	0001b517          	auipc	a0,0x1b
    80003e04:	7b850513          	addi	a0,a0,1976 # 8001f5b8 <itable>
    80003e08:	ffffd097          	auipc	ra,0xffffd
    80003e0c:	e82080e7          	jalr	-382(ra) # 80000c8a <release>
}
    80003e10:	60e2                	ld	ra,24(sp)
    80003e12:	6442                	ld	s0,16(sp)
    80003e14:	64a2                	ld	s1,8(sp)
    80003e16:	6902                	ld	s2,0(sp)
    80003e18:	6105                	addi	sp,sp,32
    80003e1a:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003e1c:	40bc                	lw	a5,64(s1)
    80003e1e:	dff1                	beqz	a5,80003dfa <iput+0x26>
    80003e20:	04a49783          	lh	a5,74(s1)
    80003e24:	fbf9                	bnez	a5,80003dfa <iput+0x26>
    acquiresleep(&ip->lock);
    80003e26:	01048913          	addi	s2,s1,16
    80003e2a:	854a                	mv	a0,s2
    80003e2c:	00001097          	auipc	ra,0x1
    80003e30:	aae080e7          	jalr	-1362(ra) # 800048da <acquiresleep>
    release(&itable.lock);
    80003e34:	0001b517          	auipc	a0,0x1b
    80003e38:	78450513          	addi	a0,a0,1924 # 8001f5b8 <itable>
    80003e3c:	ffffd097          	auipc	ra,0xffffd
    80003e40:	e4e080e7          	jalr	-434(ra) # 80000c8a <release>
    itrunc(ip);
    80003e44:	8526                	mv	a0,s1
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	ee2080e7          	jalr	-286(ra) # 80003d28 <itrunc>
    ip->type = 0;
    80003e4e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003e52:	8526                	mv	a0,s1
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	cfa080e7          	jalr	-774(ra) # 80003b4e <iupdate>
    ip->valid = 0;
    80003e5c:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003e60:	854a                	mv	a0,s2
    80003e62:	00001097          	auipc	ra,0x1
    80003e66:	ace080e7          	jalr	-1330(ra) # 80004930 <releasesleep>
    acquire(&itable.lock);
    80003e6a:	0001b517          	auipc	a0,0x1b
    80003e6e:	74e50513          	addi	a0,a0,1870 # 8001f5b8 <itable>
    80003e72:	ffffd097          	auipc	ra,0xffffd
    80003e76:	d64080e7          	jalr	-668(ra) # 80000bd6 <acquire>
    80003e7a:	b741                	j	80003dfa <iput+0x26>

0000000080003e7c <iunlockput>:
{
    80003e7c:	1101                	addi	sp,sp,-32
    80003e7e:	ec06                	sd	ra,24(sp)
    80003e80:	e822                	sd	s0,16(sp)
    80003e82:	e426                	sd	s1,8(sp)
    80003e84:	1000                	addi	s0,sp,32
    80003e86:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e88:	00000097          	auipc	ra,0x0
    80003e8c:	e54080e7          	jalr	-428(ra) # 80003cdc <iunlock>
  iput(ip);
    80003e90:	8526                	mv	a0,s1
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	f42080e7          	jalr	-190(ra) # 80003dd4 <iput>
}
    80003e9a:	60e2                	ld	ra,24(sp)
    80003e9c:	6442                	ld	s0,16(sp)
    80003e9e:	64a2                	ld	s1,8(sp)
    80003ea0:	6105                	addi	sp,sp,32
    80003ea2:	8082                	ret

0000000080003ea4 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003ea4:	1141                	addi	sp,sp,-16
    80003ea6:	e422                	sd	s0,8(sp)
    80003ea8:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003eaa:	411c                	lw	a5,0(a0)
    80003eac:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003eae:	415c                	lw	a5,4(a0)
    80003eb0:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003eb2:	04451783          	lh	a5,68(a0)
    80003eb6:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003eba:	04a51783          	lh	a5,74(a0)
    80003ebe:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003ec2:	04c56783          	lwu	a5,76(a0)
    80003ec6:	e99c                	sd	a5,16(a1)
}
    80003ec8:	6422                	ld	s0,8(sp)
    80003eca:	0141                	addi	sp,sp,16
    80003ecc:	8082                	ret

0000000080003ece <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ece:	457c                	lw	a5,76(a0)
    80003ed0:	0ed7e963          	bltu	a5,a3,80003fc2 <readi+0xf4>
{
    80003ed4:	7159                	addi	sp,sp,-112
    80003ed6:	f486                	sd	ra,104(sp)
    80003ed8:	f0a2                	sd	s0,96(sp)
    80003eda:	eca6                	sd	s1,88(sp)
    80003edc:	e8ca                	sd	s2,80(sp)
    80003ede:	e4ce                	sd	s3,72(sp)
    80003ee0:	e0d2                	sd	s4,64(sp)
    80003ee2:	fc56                	sd	s5,56(sp)
    80003ee4:	f85a                	sd	s6,48(sp)
    80003ee6:	f45e                	sd	s7,40(sp)
    80003ee8:	f062                	sd	s8,32(sp)
    80003eea:	ec66                	sd	s9,24(sp)
    80003eec:	e86a                	sd	s10,16(sp)
    80003eee:	e46e                	sd	s11,8(sp)
    80003ef0:	1880                	addi	s0,sp,112
    80003ef2:	8b2a                	mv	s6,a0
    80003ef4:	8bae                	mv	s7,a1
    80003ef6:	8a32                	mv	s4,a2
    80003ef8:	84b6                	mv	s1,a3
    80003efa:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003efc:	9f35                	addw	a4,a4,a3
    return 0;
    80003efe:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003f00:	0ad76063          	bltu	a4,a3,80003fa0 <readi+0xd2>
  if(off + n > ip->size)
    80003f04:	00e7f463          	bgeu	a5,a4,80003f0c <readi+0x3e>
    n = ip->size - off;
    80003f08:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f0c:	0a0a8963          	beqz	s5,80003fbe <readi+0xf0>
    80003f10:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f12:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003f16:	5c7d                	li	s8,-1
    80003f18:	a82d                	j	80003f52 <readi+0x84>
    80003f1a:	020d1d93          	slli	s11,s10,0x20
    80003f1e:	020ddd93          	srli	s11,s11,0x20
    80003f22:	05890613          	addi	a2,s2,88
    80003f26:	86ee                	mv	a3,s11
    80003f28:	963a                	add	a2,a2,a4
    80003f2a:	85d2                	mv	a1,s4
    80003f2c:	855e                	mv	a0,s7
    80003f2e:	fffff097          	auipc	ra,0xfffff
    80003f32:	946080e7          	jalr	-1722(ra) # 80002874 <either_copyout>
    80003f36:	05850d63          	beq	a0,s8,80003f90 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003f3a:	854a                	mv	a0,s2
    80003f3c:	fffff097          	auipc	ra,0xfffff
    80003f40:	5f6080e7          	jalr	1526(ra) # 80003532 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f44:	013d09bb          	addw	s3,s10,s3
    80003f48:	009d04bb          	addw	s1,s10,s1
    80003f4c:	9a6e                	add	s4,s4,s11
    80003f4e:	0559f763          	bgeu	s3,s5,80003f9c <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003f52:	00a4d59b          	srliw	a1,s1,0xa
    80003f56:	855a                	mv	a0,s6
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	89e080e7          	jalr	-1890(ra) # 800037f6 <bmap>
    80003f60:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f64:	cd85                	beqz	a1,80003f9c <readi+0xce>
    bp = bread(ip->dev, addr);
    80003f66:	000b2503          	lw	a0,0(s6)
    80003f6a:	fffff097          	auipc	ra,0xfffff
    80003f6e:	498080e7          	jalr	1176(ra) # 80003402 <bread>
    80003f72:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f74:	3ff4f713          	andi	a4,s1,1023
    80003f78:	40ec87bb          	subw	a5,s9,a4
    80003f7c:	413a86bb          	subw	a3,s5,s3
    80003f80:	8d3e                	mv	s10,a5
    80003f82:	2781                	sext.w	a5,a5
    80003f84:	0006861b          	sext.w	a2,a3
    80003f88:	f8f679e3          	bgeu	a2,a5,80003f1a <readi+0x4c>
    80003f8c:	8d36                	mv	s10,a3
    80003f8e:	b771                	j	80003f1a <readi+0x4c>
      brelse(bp);
    80003f90:	854a                	mv	a0,s2
    80003f92:	fffff097          	auipc	ra,0xfffff
    80003f96:	5a0080e7          	jalr	1440(ra) # 80003532 <brelse>
      tot = -1;
    80003f9a:	59fd                	li	s3,-1
  }
  return tot;
    80003f9c:	0009851b          	sext.w	a0,s3
}
    80003fa0:	70a6                	ld	ra,104(sp)
    80003fa2:	7406                	ld	s0,96(sp)
    80003fa4:	64e6                	ld	s1,88(sp)
    80003fa6:	6946                	ld	s2,80(sp)
    80003fa8:	69a6                	ld	s3,72(sp)
    80003faa:	6a06                	ld	s4,64(sp)
    80003fac:	7ae2                	ld	s5,56(sp)
    80003fae:	7b42                	ld	s6,48(sp)
    80003fb0:	7ba2                	ld	s7,40(sp)
    80003fb2:	7c02                	ld	s8,32(sp)
    80003fb4:	6ce2                	ld	s9,24(sp)
    80003fb6:	6d42                	ld	s10,16(sp)
    80003fb8:	6da2                	ld	s11,8(sp)
    80003fba:	6165                	addi	sp,sp,112
    80003fbc:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003fbe:	89d6                	mv	s3,s5
    80003fc0:	bff1                	j	80003f9c <readi+0xce>
    return 0;
    80003fc2:	4501                	li	a0,0
}
    80003fc4:	8082                	ret

0000000080003fc6 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003fc6:	457c                	lw	a5,76(a0)
    80003fc8:	10d7e863          	bltu	a5,a3,800040d8 <writei+0x112>
{
    80003fcc:	7159                	addi	sp,sp,-112
    80003fce:	f486                	sd	ra,104(sp)
    80003fd0:	f0a2                	sd	s0,96(sp)
    80003fd2:	eca6                	sd	s1,88(sp)
    80003fd4:	e8ca                	sd	s2,80(sp)
    80003fd6:	e4ce                	sd	s3,72(sp)
    80003fd8:	e0d2                	sd	s4,64(sp)
    80003fda:	fc56                	sd	s5,56(sp)
    80003fdc:	f85a                	sd	s6,48(sp)
    80003fde:	f45e                	sd	s7,40(sp)
    80003fe0:	f062                	sd	s8,32(sp)
    80003fe2:	ec66                	sd	s9,24(sp)
    80003fe4:	e86a                	sd	s10,16(sp)
    80003fe6:	e46e                	sd	s11,8(sp)
    80003fe8:	1880                	addi	s0,sp,112
    80003fea:	8aaa                	mv	s5,a0
    80003fec:	8bae                	mv	s7,a1
    80003fee:	8a32                	mv	s4,a2
    80003ff0:	8936                	mv	s2,a3
    80003ff2:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ff4:	00e687bb          	addw	a5,a3,a4
    80003ff8:	0ed7e263          	bltu	a5,a3,800040dc <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ffc:	00043737          	lui	a4,0x43
    80004000:	0ef76063          	bltu	a4,a5,800040e0 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004004:	0c0b0863          	beqz	s6,800040d4 <writei+0x10e>
    80004008:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000400a:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    8000400e:	5c7d                	li	s8,-1
    80004010:	a091                	j	80004054 <writei+0x8e>
    80004012:	020d1d93          	slli	s11,s10,0x20
    80004016:	020ddd93          	srli	s11,s11,0x20
    8000401a:	05848513          	addi	a0,s1,88
    8000401e:	86ee                	mv	a3,s11
    80004020:	8652                	mv	a2,s4
    80004022:	85de                	mv	a1,s7
    80004024:	953a                	add	a0,a0,a4
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	8a4080e7          	jalr	-1884(ra) # 800028ca <either_copyin>
    8000402e:	07850263          	beq	a0,s8,80004092 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004032:	8526                	mv	a0,s1
    80004034:	00000097          	auipc	ra,0x0
    80004038:	788080e7          	jalr	1928(ra) # 800047bc <log_write>
    brelse(bp);
    8000403c:	8526                	mv	a0,s1
    8000403e:	fffff097          	auipc	ra,0xfffff
    80004042:	4f4080e7          	jalr	1268(ra) # 80003532 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004046:	013d09bb          	addw	s3,s10,s3
    8000404a:	012d093b          	addw	s2,s10,s2
    8000404e:	9a6e                	add	s4,s4,s11
    80004050:	0569f663          	bgeu	s3,s6,8000409c <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004054:	00a9559b          	srliw	a1,s2,0xa
    80004058:	8556                	mv	a0,s5
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	79c080e7          	jalr	1948(ra) # 800037f6 <bmap>
    80004062:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004066:	c99d                	beqz	a1,8000409c <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004068:	000aa503          	lw	a0,0(s5)
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	396080e7          	jalr	918(ra) # 80003402 <bread>
    80004074:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004076:	3ff97713          	andi	a4,s2,1023
    8000407a:	40ec87bb          	subw	a5,s9,a4
    8000407e:	413b06bb          	subw	a3,s6,s3
    80004082:	8d3e                	mv	s10,a5
    80004084:	2781                	sext.w	a5,a5
    80004086:	0006861b          	sext.w	a2,a3
    8000408a:	f8f674e3          	bgeu	a2,a5,80004012 <writei+0x4c>
    8000408e:	8d36                	mv	s10,a3
    80004090:	b749                	j	80004012 <writei+0x4c>
      brelse(bp);
    80004092:	8526                	mv	a0,s1
    80004094:	fffff097          	auipc	ra,0xfffff
    80004098:	49e080e7          	jalr	1182(ra) # 80003532 <brelse>
  }

  if(off > ip->size)
    8000409c:	04caa783          	lw	a5,76(s5)
    800040a0:	0127f463          	bgeu	a5,s2,800040a8 <writei+0xe2>
    ip->size = off;
    800040a4:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800040a8:	8556                	mv	a0,s5
    800040aa:	00000097          	auipc	ra,0x0
    800040ae:	aa4080e7          	jalr	-1372(ra) # 80003b4e <iupdate>

  return tot;
    800040b2:	0009851b          	sext.w	a0,s3
}
    800040b6:	70a6                	ld	ra,104(sp)
    800040b8:	7406                	ld	s0,96(sp)
    800040ba:	64e6                	ld	s1,88(sp)
    800040bc:	6946                	ld	s2,80(sp)
    800040be:	69a6                	ld	s3,72(sp)
    800040c0:	6a06                	ld	s4,64(sp)
    800040c2:	7ae2                	ld	s5,56(sp)
    800040c4:	7b42                	ld	s6,48(sp)
    800040c6:	7ba2                	ld	s7,40(sp)
    800040c8:	7c02                	ld	s8,32(sp)
    800040ca:	6ce2                	ld	s9,24(sp)
    800040cc:	6d42                	ld	s10,16(sp)
    800040ce:	6da2                	ld	s11,8(sp)
    800040d0:	6165                	addi	sp,sp,112
    800040d2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800040d4:	89da                	mv	s3,s6
    800040d6:	bfc9                	j	800040a8 <writei+0xe2>
    return -1;
    800040d8:	557d                	li	a0,-1
}
    800040da:	8082                	ret
    return -1;
    800040dc:	557d                	li	a0,-1
    800040de:	bfe1                	j	800040b6 <writei+0xf0>
    return -1;
    800040e0:	557d                	li	a0,-1
    800040e2:	bfd1                	j	800040b6 <writei+0xf0>

00000000800040e4 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800040e4:	1141                	addi	sp,sp,-16
    800040e6:	e406                	sd	ra,8(sp)
    800040e8:	e022                	sd	s0,0(sp)
    800040ea:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800040ec:	4639                	li	a2,14
    800040ee:	ffffd097          	auipc	ra,0xffffd
    800040f2:	cb4080e7          	jalr	-844(ra) # 80000da2 <strncmp>
}
    800040f6:	60a2                	ld	ra,8(sp)
    800040f8:	6402                	ld	s0,0(sp)
    800040fa:	0141                	addi	sp,sp,16
    800040fc:	8082                	ret

00000000800040fe <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800040fe:	7139                	addi	sp,sp,-64
    80004100:	fc06                	sd	ra,56(sp)
    80004102:	f822                	sd	s0,48(sp)
    80004104:	f426                	sd	s1,40(sp)
    80004106:	f04a                	sd	s2,32(sp)
    80004108:	ec4e                	sd	s3,24(sp)
    8000410a:	e852                	sd	s4,16(sp)
    8000410c:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000410e:	04451703          	lh	a4,68(a0)
    80004112:	4785                	li	a5,1
    80004114:	00f71a63          	bne	a4,a5,80004128 <dirlookup+0x2a>
    80004118:	892a                	mv	s2,a0
    8000411a:	89ae                	mv	s3,a1
    8000411c:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000411e:	457c                	lw	a5,76(a0)
    80004120:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004122:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004124:	e79d                	bnez	a5,80004152 <dirlookup+0x54>
    80004126:	a8a5                	j	8000419e <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004128:	00004517          	auipc	a0,0x4
    8000412c:	5b050513          	addi	a0,a0,1456 # 800086d8 <syscalls+0x1b8>
    80004130:	ffffc097          	auipc	ra,0xffffc
    80004134:	410080e7          	jalr	1040(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004138:	00004517          	auipc	a0,0x4
    8000413c:	5b850513          	addi	a0,a0,1464 # 800086f0 <syscalls+0x1d0>
    80004140:	ffffc097          	auipc	ra,0xffffc
    80004144:	400080e7          	jalr	1024(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004148:	24c1                	addiw	s1,s1,16
    8000414a:	04c92783          	lw	a5,76(s2)
    8000414e:	04f4f763          	bgeu	s1,a5,8000419c <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004152:	4741                	li	a4,16
    80004154:	86a6                	mv	a3,s1
    80004156:	fc040613          	addi	a2,s0,-64
    8000415a:	4581                	li	a1,0
    8000415c:	854a                	mv	a0,s2
    8000415e:	00000097          	auipc	ra,0x0
    80004162:	d70080e7          	jalr	-656(ra) # 80003ece <readi>
    80004166:	47c1                	li	a5,16
    80004168:	fcf518e3          	bne	a0,a5,80004138 <dirlookup+0x3a>
    if(de.inum == 0)
    8000416c:	fc045783          	lhu	a5,-64(s0)
    80004170:	dfe1                	beqz	a5,80004148 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004172:	fc240593          	addi	a1,s0,-62
    80004176:	854e                	mv	a0,s3
    80004178:	00000097          	auipc	ra,0x0
    8000417c:	f6c080e7          	jalr	-148(ra) # 800040e4 <namecmp>
    80004180:	f561                	bnez	a0,80004148 <dirlookup+0x4a>
      if(poff)
    80004182:	000a0463          	beqz	s4,8000418a <dirlookup+0x8c>
        *poff = off;
    80004186:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000418a:	fc045583          	lhu	a1,-64(s0)
    8000418e:	00092503          	lw	a0,0(s2)
    80004192:	fffff097          	auipc	ra,0xfffff
    80004196:	74e080e7          	jalr	1870(ra) # 800038e0 <iget>
    8000419a:	a011                	j	8000419e <dirlookup+0xa0>
  return 0;
    8000419c:	4501                	li	a0,0
}
    8000419e:	70e2                	ld	ra,56(sp)
    800041a0:	7442                	ld	s0,48(sp)
    800041a2:	74a2                	ld	s1,40(sp)
    800041a4:	7902                	ld	s2,32(sp)
    800041a6:	69e2                	ld	s3,24(sp)
    800041a8:	6a42                	ld	s4,16(sp)
    800041aa:	6121                	addi	sp,sp,64
    800041ac:	8082                	ret

00000000800041ae <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800041ae:	711d                	addi	sp,sp,-96
    800041b0:	ec86                	sd	ra,88(sp)
    800041b2:	e8a2                	sd	s0,80(sp)
    800041b4:	e4a6                	sd	s1,72(sp)
    800041b6:	e0ca                	sd	s2,64(sp)
    800041b8:	fc4e                	sd	s3,56(sp)
    800041ba:	f852                	sd	s4,48(sp)
    800041bc:	f456                	sd	s5,40(sp)
    800041be:	f05a                	sd	s6,32(sp)
    800041c0:	ec5e                	sd	s7,24(sp)
    800041c2:	e862                	sd	s8,16(sp)
    800041c4:	e466                	sd	s9,8(sp)
    800041c6:	e06a                	sd	s10,0(sp)
    800041c8:	1080                	addi	s0,sp,96
    800041ca:	84aa                	mv	s1,a0
    800041cc:	8b2e                	mv	s6,a1
    800041ce:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800041d0:	00054703          	lbu	a4,0(a0)
    800041d4:	02f00793          	li	a5,47
    800041d8:	02f70363          	beq	a4,a5,800041fe <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800041dc:	ffffe097          	auipc	ra,0xffffe
    800041e0:	8ae080e7          	jalr	-1874(ra) # 80001a8a <myproc>
    800041e4:	16053503          	ld	a0,352(a0)
    800041e8:	00000097          	auipc	ra,0x0
    800041ec:	9f4080e7          	jalr	-1548(ra) # 80003bdc <idup>
    800041f0:	8a2a                	mv	s4,a0
  while(*path == '/')
    800041f2:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800041f6:	4cb5                	li	s9,13
  len = path - s;
    800041f8:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800041fa:	4c05                	li	s8,1
    800041fc:	a87d                	j	800042ba <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800041fe:	4585                	li	a1,1
    80004200:	4505                	li	a0,1
    80004202:	fffff097          	auipc	ra,0xfffff
    80004206:	6de080e7          	jalr	1758(ra) # 800038e0 <iget>
    8000420a:	8a2a                	mv	s4,a0
    8000420c:	b7dd                	j	800041f2 <namex+0x44>
      iunlockput(ip);
    8000420e:	8552                	mv	a0,s4
    80004210:	00000097          	auipc	ra,0x0
    80004214:	c6c080e7          	jalr	-916(ra) # 80003e7c <iunlockput>
      return 0;
    80004218:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000421a:	8552                	mv	a0,s4
    8000421c:	60e6                	ld	ra,88(sp)
    8000421e:	6446                	ld	s0,80(sp)
    80004220:	64a6                	ld	s1,72(sp)
    80004222:	6906                	ld	s2,64(sp)
    80004224:	79e2                	ld	s3,56(sp)
    80004226:	7a42                	ld	s4,48(sp)
    80004228:	7aa2                	ld	s5,40(sp)
    8000422a:	7b02                	ld	s6,32(sp)
    8000422c:	6be2                	ld	s7,24(sp)
    8000422e:	6c42                	ld	s8,16(sp)
    80004230:	6ca2                	ld	s9,8(sp)
    80004232:	6d02                	ld	s10,0(sp)
    80004234:	6125                	addi	sp,sp,96
    80004236:	8082                	ret
      iunlock(ip);
    80004238:	8552                	mv	a0,s4
    8000423a:	00000097          	auipc	ra,0x0
    8000423e:	aa2080e7          	jalr	-1374(ra) # 80003cdc <iunlock>
      return ip;
    80004242:	bfe1                	j	8000421a <namex+0x6c>
      iunlockput(ip);
    80004244:	8552                	mv	a0,s4
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	c36080e7          	jalr	-970(ra) # 80003e7c <iunlockput>
      return 0;
    8000424e:	8a4e                	mv	s4,s3
    80004250:	b7e9                	j	8000421a <namex+0x6c>
  len = path - s;
    80004252:	40998633          	sub	a2,s3,s1
    80004256:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    8000425a:	09acd863          	bge	s9,s10,800042ea <namex+0x13c>
    memmove(name, s, DIRSIZ);
    8000425e:	4639                	li	a2,14
    80004260:	85a6                	mv	a1,s1
    80004262:	8556                	mv	a0,s5
    80004264:	ffffd097          	auipc	ra,0xffffd
    80004268:	aca080e7          	jalr	-1334(ra) # 80000d2e <memmove>
    8000426c:	84ce                	mv	s1,s3
  while(*path == '/')
    8000426e:	0004c783          	lbu	a5,0(s1)
    80004272:	01279763          	bne	a5,s2,80004280 <namex+0xd2>
    path++;
    80004276:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004278:	0004c783          	lbu	a5,0(s1)
    8000427c:	ff278de3          	beq	a5,s2,80004276 <namex+0xc8>
    ilock(ip);
    80004280:	8552                	mv	a0,s4
    80004282:	00000097          	auipc	ra,0x0
    80004286:	998080e7          	jalr	-1640(ra) # 80003c1a <ilock>
    if(ip->type != T_DIR){
    8000428a:	044a1783          	lh	a5,68(s4)
    8000428e:	f98790e3          	bne	a5,s8,8000420e <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004292:	000b0563          	beqz	s6,8000429c <namex+0xee>
    80004296:	0004c783          	lbu	a5,0(s1)
    8000429a:	dfd9                	beqz	a5,80004238 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000429c:	865e                	mv	a2,s7
    8000429e:	85d6                	mv	a1,s5
    800042a0:	8552                	mv	a0,s4
    800042a2:	00000097          	auipc	ra,0x0
    800042a6:	e5c080e7          	jalr	-420(ra) # 800040fe <dirlookup>
    800042aa:	89aa                	mv	s3,a0
    800042ac:	dd41                	beqz	a0,80004244 <namex+0x96>
    iunlockput(ip);
    800042ae:	8552                	mv	a0,s4
    800042b0:	00000097          	auipc	ra,0x0
    800042b4:	bcc080e7          	jalr	-1076(ra) # 80003e7c <iunlockput>
    ip = next;
    800042b8:	8a4e                	mv	s4,s3
  while(*path == '/')
    800042ba:	0004c783          	lbu	a5,0(s1)
    800042be:	01279763          	bne	a5,s2,800042cc <namex+0x11e>
    path++;
    800042c2:	0485                	addi	s1,s1,1
  while(*path == '/')
    800042c4:	0004c783          	lbu	a5,0(s1)
    800042c8:	ff278de3          	beq	a5,s2,800042c2 <namex+0x114>
  if(*path == 0)
    800042cc:	cb9d                	beqz	a5,80004302 <namex+0x154>
  while(*path != '/' && *path != 0)
    800042ce:	0004c783          	lbu	a5,0(s1)
    800042d2:	89a6                	mv	s3,s1
  len = path - s;
    800042d4:	8d5e                	mv	s10,s7
    800042d6:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800042d8:	01278963          	beq	a5,s2,800042ea <namex+0x13c>
    800042dc:	dbbd                	beqz	a5,80004252 <namex+0xa4>
    path++;
    800042de:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800042e0:	0009c783          	lbu	a5,0(s3)
    800042e4:	ff279ce3          	bne	a5,s2,800042dc <namex+0x12e>
    800042e8:	b7ad                	j	80004252 <namex+0xa4>
    memmove(name, s, len);
    800042ea:	2601                	sext.w	a2,a2
    800042ec:	85a6                	mv	a1,s1
    800042ee:	8556                	mv	a0,s5
    800042f0:	ffffd097          	auipc	ra,0xffffd
    800042f4:	a3e080e7          	jalr	-1474(ra) # 80000d2e <memmove>
    name[len] = 0;
    800042f8:	9d56                	add	s10,s10,s5
    800042fa:	000d0023          	sb	zero,0(s10)
    800042fe:	84ce                	mv	s1,s3
    80004300:	b7bd                	j	8000426e <namex+0xc0>
  if(nameiparent){
    80004302:	f00b0ce3          	beqz	s6,8000421a <namex+0x6c>
    iput(ip);
    80004306:	8552                	mv	a0,s4
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	acc080e7          	jalr	-1332(ra) # 80003dd4 <iput>
    return 0;
    80004310:	4a01                	li	s4,0
    80004312:	b721                	j	8000421a <namex+0x6c>

0000000080004314 <dirlink>:
{
    80004314:	7139                	addi	sp,sp,-64
    80004316:	fc06                	sd	ra,56(sp)
    80004318:	f822                	sd	s0,48(sp)
    8000431a:	f426                	sd	s1,40(sp)
    8000431c:	f04a                	sd	s2,32(sp)
    8000431e:	ec4e                	sd	s3,24(sp)
    80004320:	e852                	sd	s4,16(sp)
    80004322:	0080                	addi	s0,sp,64
    80004324:	892a                	mv	s2,a0
    80004326:	8a2e                	mv	s4,a1
    80004328:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000432a:	4601                	li	a2,0
    8000432c:	00000097          	auipc	ra,0x0
    80004330:	dd2080e7          	jalr	-558(ra) # 800040fe <dirlookup>
    80004334:	e93d                	bnez	a0,800043aa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004336:	04c92483          	lw	s1,76(s2)
    8000433a:	c49d                	beqz	s1,80004368 <dirlink+0x54>
    8000433c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000433e:	4741                	li	a4,16
    80004340:	86a6                	mv	a3,s1
    80004342:	fc040613          	addi	a2,s0,-64
    80004346:	4581                	li	a1,0
    80004348:	854a                	mv	a0,s2
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	b84080e7          	jalr	-1148(ra) # 80003ece <readi>
    80004352:	47c1                	li	a5,16
    80004354:	06f51163          	bne	a0,a5,800043b6 <dirlink+0xa2>
    if(de.inum == 0)
    80004358:	fc045783          	lhu	a5,-64(s0)
    8000435c:	c791                	beqz	a5,80004368 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000435e:	24c1                	addiw	s1,s1,16
    80004360:	04c92783          	lw	a5,76(s2)
    80004364:	fcf4ede3          	bltu	s1,a5,8000433e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004368:	4639                	li	a2,14
    8000436a:	85d2                	mv	a1,s4
    8000436c:	fc240513          	addi	a0,s0,-62
    80004370:	ffffd097          	auipc	ra,0xffffd
    80004374:	a6e080e7          	jalr	-1426(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004378:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000437c:	4741                	li	a4,16
    8000437e:	86a6                	mv	a3,s1
    80004380:	fc040613          	addi	a2,s0,-64
    80004384:	4581                	li	a1,0
    80004386:	854a                	mv	a0,s2
    80004388:	00000097          	auipc	ra,0x0
    8000438c:	c3e080e7          	jalr	-962(ra) # 80003fc6 <writei>
    80004390:	1541                	addi	a0,a0,-16
    80004392:	00a03533          	snez	a0,a0
    80004396:	40a00533          	neg	a0,a0
}
    8000439a:	70e2                	ld	ra,56(sp)
    8000439c:	7442                	ld	s0,48(sp)
    8000439e:	74a2                	ld	s1,40(sp)
    800043a0:	7902                	ld	s2,32(sp)
    800043a2:	69e2                	ld	s3,24(sp)
    800043a4:	6a42                	ld	s4,16(sp)
    800043a6:	6121                	addi	sp,sp,64
    800043a8:	8082                	ret
    iput(ip);
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	a2a080e7          	jalr	-1494(ra) # 80003dd4 <iput>
    return -1;
    800043b2:	557d                	li	a0,-1
    800043b4:	b7dd                	j	8000439a <dirlink+0x86>
      panic("dirlink read");
    800043b6:	00004517          	auipc	a0,0x4
    800043ba:	34a50513          	addi	a0,a0,842 # 80008700 <syscalls+0x1e0>
    800043be:	ffffc097          	auipc	ra,0xffffc
    800043c2:	182080e7          	jalr	386(ra) # 80000540 <panic>

00000000800043c6 <namei>:

struct inode*
namei(char *path)
{
    800043c6:	1101                	addi	sp,sp,-32
    800043c8:	ec06                	sd	ra,24(sp)
    800043ca:	e822                	sd	s0,16(sp)
    800043cc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800043ce:	fe040613          	addi	a2,s0,-32
    800043d2:	4581                	li	a1,0
    800043d4:	00000097          	auipc	ra,0x0
    800043d8:	dda080e7          	jalr	-550(ra) # 800041ae <namex>
}
    800043dc:	60e2                	ld	ra,24(sp)
    800043de:	6442                	ld	s0,16(sp)
    800043e0:	6105                	addi	sp,sp,32
    800043e2:	8082                	ret

00000000800043e4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800043e4:	1141                	addi	sp,sp,-16
    800043e6:	e406                	sd	ra,8(sp)
    800043e8:	e022                	sd	s0,0(sp)
    800043ea:	0800                	addi	s0,sp,16
    800043ec:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800043ee:	4585                	li	a1,1
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	dbe080e7          	jalr	-578(ra) # 800041ae <namex>
}
    800043f8:	60a2                	ld	ra,8(sp)
    800043fa:	6402                	ld	s0,0(sp)
    800043fc:	0141                	addi	sp,sp,16
    800043fe:	8082                	ret

0000000080004400 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004400:	1101                	addi	sp,sp,-32
    80004402:	ec06                	sd	ra,24(sp)
    80004404:	e822                	sd	s0,16(sp)
    80004406:	e426                	sd	s1,8(sp)
    80004408:	e04a                	sd	s2,0(sp)
    8000440a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000440c:	0001d917          	auipc	s2,0x1d
    80004410:	c5490913          	addi	s2,s2,-940 # 80021060 <log>
    80004414:	01892583          	lw	a1,24(s2)
    80004418:	02892503          	lw	a0,40(s2)
    8000441c:	fffff097          	auipc	ra,0xfffff
    80004420:	fe6080e7          	jalr	-26(ra) # 80003402 <bread>
    80004424:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004426:	02c92683          	lw	a3,44(s2)
    8000442a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000442c:	02d05863          	blez	a3,8000445c <write_head+0x5c>
    80004430:	0001d797          	auipc	a5,0x1d
    80004434:	c6078793          	addi	a5,a5,-928 # 80021090 <log+0x30>
    80004438:	05c50713          	addi	a4,a0,92
    8000443c:	36fd                	addiw	a3,a3,-1
    8000443e:	02069613          	slli	a2,a3,0x20
    80004442:	01e65693          	srli	a3,a2,0x1e
    80004446:	0001d617          	auipc	a2,0x1d
    8000444a:	c4e60613          	addi	a2,a2,-946 # 80021094 <log+0x34>
    8000444e:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004450:	4390                	lw	a2,0(a5)
    80004452:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004454:	0791                	addi	a5,a5,4
    80004456:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004458:	fed79ce3          	bne	a5,a3,80004450 <write_head+0x50>
  }
  bwrite(buf);
    8000445c:	8526                	mv	a0,s1
    8000445e:	fffff097          	auipc	ra,0xfffff
    80004462:	096080e7          	jalr	150(ra) # 800034f4 <bwrite>
  brelse(buf);
    80004466:	8526                	mv	a0,s1
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	0ca080e7          	jalr	202(ra) # 80003532 <brelse>
}
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6902                	ld	s2,0(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret

000000008000447c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000447c:	0001d797          	auipc	a5,0x1d
    80004480:	c107a783          	lw	a5,-1008(a5) # 8002108c <log+0x2c>
    80004484:	0af05d63          	blez	a5,8000453e <install_trans+0xc2>
{
    80004488:	7139                	addi	sp,sp,-64
    8000448a:	fc06                	sd	ra,56(sp)
    8000448c:	f822                	sd	s0,48(sp)
    8000448e:	f426                	sd	s1,40(sp)
    80004490:	f04a                	sd	s2,32(sp)
    80004492:	ec4e                	sd	s3,24(sp)
    80004494:	e852                	sd	s4,16(sp)
    80004496:	e456                	sd	s5,8(sp)
    80004498:	e05a                	sd	s6,0(sp)
    8000449a:	0080                	addi	s0,sp,64
    8000449c:	8b2a                	mv	s6,a0
    8000449e:	0001da97          	auipc	s5,0x1d
    800044a2:	bf2a8a93          	addi	s5,s5,-1038 # 80021090 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044a6:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044a8:	0001d997          	auipc	s3,0x1d
    800044ac:	bb898993          	addi	s3,s3,-1096 # 80021060 <log>
    800044b0:	a00d                	j	800044d2 <install_trans+0x56>
    brelse(lbuf);
    800044b2:	854a                	mv	a0,s2
    800044b4:	fffff097          	auipc	ra,0xfffff
    800044b8:	07e080e7          	jalr	126(ra) # 80003532 <brelse>
    brelse(dbuf);
    800044bc:	8526                	mv	a0,s1
    800044be:	fffff097          	auipc	ra,0xfffff
    800044c2:	074080e7          	jalr	116(ra) # 80003532 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044c6:	2a05                	addiw	s4,s4,1
    800044c8:	0a91                	addi	s5,s5,4
    800044ca:	02c9a783          	lw	a5,44(s3)
    800044ce:	04fa5e63          	bge	s4,a5,8000452a <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800044d2:	0189a583          	lw	a1,24(s3)
    800044d6:	014585bb          	addw	a1,a1,s4
    800044da:	2585                	addiw	a1,a1,1
    800044dc:	0289a503          	lw	a0,40(s3)
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	f22080e7          	jalr	-222(ra) # 80003402 <bread>
    800044e8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800044ea:	000aa583          	lw	a1,0(s5)
    800044ee:	0289a503          	lw	a0,40(s3)
    800044f2:	fffff097          	auipc	ra,0xfffff
    800044f6:	f10080e7          	jalr	-240(ra) # 80003402 <bread>
    800044fa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800044fc:	40000613          	li	a2,1024
    80004500:	05890593          	addi	a1,s2,88
    80004504:	05850513          	addi	a0,a0,88
    80004508:	ffffd097          	auipc	ra,0xffffd
    8000450c:	826080e7          	jalr	-2010(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004510:	8526                	mv	a0,s1
    80004512:	fffff097          	auipc	ra,0xfffff
    80004516:	fe2080e7          	jalr	-30(ra) # 800034f4 <bwrite>
    if(recovering == 0)
    8000451a:	f80b1ce3          	bnez	s6,800044b2 <install_trans+0x36>
      bunpin(dbuf);
    8000451e:	8526                	mv	a0,s1
    80004520:	fffff097          	auipc	ra,0xfffff
    80004524:	0ec080e7          	jalr	236(ra) # 8000360c <bunpin>
    80004528:	b769                	j	800044b2 <install_trans+0x36>
}
    8000452a:	70e2                	ld	ra,56(sp)
    8000452c:	7442                	ld	s0,48(sp)
    8000452e:	74a2                	ld	s1,40(sp)
    80004530:	7902                	ld	s2,32(sp)
    80004532:	69e2                	ld	s3,24(sp)
    80004534:	6a42                	ld	s4,16(sp)
    80004536:	6aa2                	ld	s5,8(sp)
    80004538:	6b02                	ld	s6,0(sp)
    8000453a:	6121                	addi	sp,sp,64
    8000453c:	8082                	ret
    8000453e:	8082                	ret

0000000080004540 <initlog>:
{
    80004540:	7179                	addi	sp,sp,-48
    80004542:	f406                	sd	ra,40(sp)
    80004544:	f022                	sd	s0,32(sp)
    80004546:	ec26                	sd	s1,24(sp)
    80004548:	e84a                	sd	s2,16(sp)
    8000454a:	e44e                	sd	s3,8(sp)
    8000454c:	1800                	addi	s0,sp,48
    8000454e:	892a                	mv	s2,a0
    80004550:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004552:	0001d497          	auipc	s1,0x1d
    80004556:	b0e48493          	addi	s1,s1,-1266 # 80021060 <log>
    8000455a:	00004597          	auipc	a1,0x4
    8000455e:	1b658593          	addi	a1,a1,438 # 80008710 <syscalls+0x1f0>
    80004562:	8526                	mv	a0,s1
    80004564:	ffffc097          	auipc	ra,0xffffc
    80004568:	5e2080e7          	jalr	1506(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    8000456c:	0149a583          	lw	a1,20(s3)
    80004570:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004572:	0109a783          	lw	a5,16(s3)
    80004576:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004578:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000457c:	854a                	mv	a0,s2
    8000457e:	fffff097          	auipc	ra,0xfffff
    80004582:	e84080e7          	jalr	-380(ra) # 80003402 <bread>
  log.lh.n = lh->n;
    80004586:	4d34                	lw	a3,88(a0)
    80004588:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000458a:	02d05663          	blez	a3,800045b6 <initlog+0x76>
    8000458e:	05c50793          	addi	a5,a0,92
    80004592:	0001d717          	auipc	a4,0x1d
    80004596:	afe70713          	addi	a4,a4,-1282 # 80021090 <log+0x30>
    8000459a:	36fd                	addiw	a3,a3,-1
    8000459c:	02069613          	slli	a2,a3,0x20
    800045a0:	01e65693          	srli	a3,a2,0x1e
    800045a4:	06050613          	addi	a2,a0,96
    800045a8:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    800045aa:	4390                	lw	a2,0(a5)
    800045ac:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045ae:	0791                	addi	a5,a5,4
    800045b0:	0711                	addi	a4,a4,4
    800045b2:	fed79ce3          	bne	a5,a3,800045aa <initlog+0x6a>
  brelse(buf);
    800045b6:	fffff097          	auipc	ra,0xfffff
    800045ba:	f7c080e7          	jalr	-132(ra) # 80003532 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    800045be:	4505                	li	a0,1
    800045c0:	00000097          	auipc	ra,0x0
    800045c4:	ebc080e7          	jalr	-324(ra) # 8000447c <install_trans>
  log.lh.n = 0;
    800045c8:	0001d797          	auipc	a5,0x1d
    800045cc:	ac07a223          	sw	zero,-1340(a5) # 8002108c <log+0x2c>
  write_head(); // clear the log
    800045d0:	00000097          	auipc	ra,0x0
    800045d4:	e30080e7          	jalr	-464(ra) # 80004400 <write_head>
}
    800045d8:	70a2                	ld	ra,40(sp)
    800045da:	7402                	ld	s0,32(sp)
    800045dc:	64e2                	ld	s1,24(sp)
    800045de:	6942                	ld	s2,16(sp)
    800045e0:	69a2                	ld	s3,8(sp)
    800045e2:	6145                	addi	sp,sp,48
    800045e4:	8082                	ret

00000000800045e6 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800045e6:	1101                	addi	sp,sp,-32
    800045e8:	ec06                	sd	ra,24(sp)
    800045ea:	e822                	sd	s0,16(sp)
    800045ec:	e426                	sd	s1,8(sp)
    800045ee:	e04a                	sd	s2,0(sp)
    800045f0:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800045f2:	0001d517          	auipc	a0,0x1d
    800045f6:	a6e50513          	addi	a0,a0,-1426 # 80021060 <log>
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	5dc080e7          	jalr	1500(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004602:	0001d497          	auipc	s1,0x1d
    80004606:	a5e48493          	addi	s1,s1,-1442 # 80021060 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000460a:	4979                	li	s2,30
    8000460c:	a039                	j	8000461a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000460e:	85a6                	mv	a1,s1
    80004610:	8526                	mv	a0,s1
    80004612:	ffffe097          	auipc	ra,0xffffe
    80004616:	e5a080e7          	jalr	-422(ra) # 8000246c <sleep>
    if(log.committing){
    8000461a:	50dc                	lw	a5,36(s1)
    8000461c:	fbed                	bnez	a5,8000460e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000461e:	5098                	lw	a4,32(s1)
    80004620:	2705                	addiw	a4,a4,1
    80004622:	0007069b          	sext.w	a3,a4
    80004626:	0027179b          	slliw	a5,a4,0x2
    8000462a:	9fb9                	addw	a5,a5,a4
    8000462c:	0017979b          	slliw	a5,a5,0x1
    80004630:	54d8                	lw	a4,44(s1)
    80004632:	9fb9                	addw	a5,a5,a4
    80004634:	00f95963          	bge	s2,a5,80004646 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004638:	85a6                	mv	a1,s1
    8000463a:	8526                	mv	a0,s1
    8000463c:	ffffe097          	auipc	ra,0xffffe
    80004640:	e30080e7          	jalr	-464(ra) # 8000246c <sleep>
    80004644:	bfd9                	j	8000461a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004646:	0001d517          	auipc	a0,0x1d
    8000464a:	a1a50513          	addi	a0,a0,-1510 # 80021060 <log>
    8000464e:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	63a080e7          	jalr	1594(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004658:	60e2                	ld	ra,24(sp)
    8000465a:	6442                	ld	s0,16(sp)
    8000465c:	64a2                	ld	s1,8(sp)
    8000465e:	6902                	ld	s2,0(sp)
    80004660:	6105                	addi	sp,sp,32
    80004662:	8082                	ret

0000000080004664 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004664:	7139                	addi	sp,sp,-64
    80004666:	fc06                	sd	ra,56(sp)
    80004668:	f822                	sd	s0,48(sp)
    8000466a:	f426                	sd	s1,40(sp)
    8000466c:	f04a                	sd	s2,32(sp)
    8000466e:	ec4e                	sd	s3,24(sp)
    80004670:	e852                	sd	s4,16(sp)
    80004672:	e456                	sd	s5,8(sp)
    80004674:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004676:	0001d497          	auipc	s1,0x1d
    8000467a:	9ea48493          	addi	s1,s1,-1558 # 80021060 <log>
    8000467e:	8526                	mv	a0,s1
    80004680:	ffffc097          	auipc	ra,0xffffc
    80004684:	556080e7          	jalr	1366(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004688:	509c                	lw	a5,32(s1)
    8000468a:	37fd                	addiw	a5,a5,-1
    8000468c:	0007891b          	sext.w	s2,a5
    80004690:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004692:	50dc                	lw	a5,36(s1)
    80004694:	e7b9                	bnez	a5,800046e2 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004696:	04091e63          	bnez	s2,800046f2 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000469a:	0001d497          	auipc	s1,0x1d
    8000469e:	9c648493          	addi	s1,s1,-1594 # 80021060 <log>
    800046a2:	4785                	li	a5,1
    800046a4:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800046a6:	8526                	mv	a0,s1
    800046a8:	ffffc097          	auipc	ra,0xffffc
    800046ac:	5e2080e7          	jalr	1506(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800046b0:	54dc                	lw	a5,44(s1)
    800046b2:	06f04763          	bgtz	a5,80004720 <end_op+0xbc>
    acquire(&log.lock);
    800046b6:	0001d497          	auipc	s1,0x1d
    800046ba:	9aa48493          	addi	s1,s1,-1622 # 80021060 <log>
    800046be:	8526                	mv	a0,s1
    800046c0:	ffffc097          	auipc	ra,0xffffc
    800046c4:	516080e7          	jalr	1302(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800046c8:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800046cc:	8526                	mv	a0,s1
    800046ce:	ffffe097          	auipc	ra,0xffffe
    800046d2:	e02080e7          	jalr	-510(ra) # 800024d0 <wakeup>
    release(&log.lock);
    800046d6:	8526                	mv	a0,s1
    800046d8:	ffffc097          	auipc	ra,0xffffc
    800046dc:	5b2080e7          	jalr	1458(ra) # 80000c8a <release>
}
    800046e0:	a03d                	j	8000470e <end_op+0xaa>
    panic("log.committing");
    800046e2:	00004517          	auipc	a0,0x4
    800046e6:	03650513          	addi	a0,a0,54 # 80008718 <syscalls+0x1f8>
    800046ea:	ffffc097          	auipc	ra,0xffffc
    800046ee:	e56080e7          	jalr	-426(ra) # 80000540 <panic>
    wakeup(&log);
    800046f2:	0001d497          	auipc	s1,0x1d
    800046f6:	96e48493          	addi	s1,s1,-1682 # 80021060 <log>
    800046fa:	8526                	mv	a0,s1
    800046fc:	ffffe097          	auipc	ra,0xffffe
    80004700:	dd4080e7          	jalr	-556(ra) # 800024d0 <wakeup>
  release(&log.lock);
    80004704:	8526                	mv	a0,s1
    80004706:	ffffc097          	auipc	ra,0xffffc
    8000470a:	584080e7          	jalr	1412(ra) # 80000c8a <release>
}
    8000470e:	70e2                	ld	ra,56(sp)
    80004710:	7442                	ld	s0,48(sp)
    80004712:	74a2                	ld	s1,40(sp)
    80004714:	7902                	ld	s2,32(sp)
    80004716:	69e2                	ld	s3,24(sp)
    80004718:	6a42                	ld	s4,16(sp)
    8000471a:	6aa2                	ld	s5,8(sp)
    8000471c:	6121                	addi	sp,sp,64
    8000471e:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004720:	0001da97          	auipc	s5,0x1d
    80004724:	970a8a93          	addi	s5,s5,-1680 # 80021090 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004728:	0001da17          	auipc	s4,0x1d
    8000472c:	938a0a13          	addi	s4,s4,-1736 # 80021060 <log>
    80004730:	018a2583          	lw	a1,24(s4)
    80004734:	012585bb          	addw	a1,a1,s2
    80004738:	2585                	addiw	a1,a1,1
    8000473a:	028a2503          	lw	a0,40(s4)
    8000473e:	fffff097          	auipc	ra,0xfffff
    80004742:	cc4080e7          	jalr	-828(ra) # 80003402 <bread>
    80004746:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004748:	000aa583          	lw	a1,0(s5)
    8000474c:	028a2503          	lw	a0,40(s4)
    80004750:	fffff097          	auipc	ra,0xfffff
    80004754:	cb2080e7          	jalr	-846(ra) # 80003402 <bread>
    80004758:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    8000475a:	40000613          	li	a2,1024
    8000475e:	05850593          	addi	a1,a0,88
    80004762:	05848513          	addi	a0,s1,88
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	5c8080e7          	jalr	1480(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000476e:	8526                	mv	a0,s1
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	d84080e7          	jalr	-636(ra) # 800034f4 <bwrite>
    brelse(from);
    80004778:	854e                	mv	a0,s3
    8000477a:	fffff097          	auipc	ra,0xfffff
    8000477e:	db8080e7          	jalr	-584(ra) # 80003532 <brelse>
    brelse(to);
    80004782:	8526                	mv	a0,s1
    80004784:	fffff097          	auipc	ra,0xfffff
    80004788:	dae080e7          	jalr	-594(ra) # 80003532 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000478c:	2905                	addiw	s2,s2,1
    8000478e:	0a91                	addi	s5,s5,4
    80004790:	02ca2783          	lw	a5,44(s4)
    80004794:	f8f94ee3          	blt	s2,a5,80004730 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004798:	00000097          	auipc	ra,0x0
    8000479c:	c68080e7          	jalr	-920(ra) # 80004400 <write_head>
    install_trans(0); // Now install writes to home locations
    800047a0:	4501                	li	a0,0
    800047a2:	00000097          	auipc	ra,0x0
    800047a6:	cda080e7          	jalr	-806(ra) # 8000447c <install_trans>
    log.lh.n = 0;
    800047aa:	0001d797          	auipc	a5,0x1d
    800047ae:	8e07a123          	sw	zero,-1822(a5) # 8002108c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800047b2:	00000097          	auipc	ra,0x0
    800047b6:	c4e080e7          	jalr	-946(ra) # 80004400 <write_head>
    800047ba:	bdf5                	j	800046b6 <end_op+0x52>

00000000800047bc <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800047bc:	1101                	addi	sp,sp,-32
    800047be:	ec06                	sd	ra,24(sp)
    800047c0:	e822                	sd	s0,16(sp)
    800047c2:	e426                	sd	s1,8(sp)
    800047c4:	e04a                	sd	s2,0(sp)
    800047c6:	1000                	addi	s0,sp,32
    800047c8:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800047ca:	0001d917          	auipc	s2,0x1d
    800047ce:	89690913          	addi	s2,s2,-1898 # 80021060 <log>
    800047d2:	854a                	mv	a0,s2
    800047d4:	ffffc097          	auipc	ra,0xffffc
    800047d8:	402080e7          	jalr	1026(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800047dc:	02c92603          	lw	a2,44(s2)
    800047e0:	47f5                	li	a5,29
    800047e2:	06c7c563          	blt	a5,a2,8000484c <log_write+0x90>
    800047e6:	0001d797          	auipc	a5,0x1d
    800047ea:	8967a783          	lw	a5,-1898(a5) # 8002107c <log+0x1c>
    800047ee:	37fd                	addiw	a5,a5,-1
    800047f0:	04f65e63          	bge	a2,a5,8000484c <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800047f4:	0001d797          	auipc	a5,0x1d
    800047f8:	88c7a783          	lw	a5,-1908(a5) # 80021080 <log+0x20>
    800047fc:	06f05063          	blez	a5,8000485c <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004800:	4781                	li	a5,0
    80004802:	06c05563          	blez	a2,8000486c <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004806:	44cc                	lw	a1,12(s1)
    80004808:	0001d717          	auipc	a4,0x1d
    8000480c:	88870713          	addi	a4,a4,-1912 # 80021090 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004810:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004812:	4314                	lw	a3,0(a4)
    80004814:	04b68c63          	beq	a3,a1,8000486c <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004818:	2785                	addiw	a5,a5,1
    8000481a:	0711                	addi	a4,a4,4
    8000481c:	fef61be3          	bne	a2,a5,80004812 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004820:	0621                	addi	a2,a2,8
    80004822:	060a                	slli	a2,a2,0x2
    80004824:	0001d797          	auipc	a5,0x1d
    80004828:	83c78793          	addi	a5,a5,-1988 # 80021060 <log>
    8000482c:	97b2                	add	a5,a5,a2
    8000482e:	44d8                	lw	a4,12(s1)
    80004830:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004832:	8526                	mv	a0,s1
    80004834:	fffff097          	auipc	ra,0xfffff
    80004838:	d9c080e7          	jalr	-612(ra) # 800035d0 <bpin>
    log.lh.n++;
    8000483c:	0001d717          	auipc	a4,0x1d
    80004840:	82470713          	addi	a4,a4,-2012 # 80021060 <log>
    80004844:	575c                	lw	a5,44(a4)
    80004846:	2785                	addiw	a5,a5,1
    80004848:	d75c                	sw	a5,44(a4)
    8000484a:	a82d                	j	80004884 <log_write+0xc8>
    panic("too big a transaction");
    8000484c:	00004517          	auipc	a0,0x4
    80004850:	edc50513          	addi	a0,a0,-292 # 80008728 <syscalls+0x208>
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	cec080e7          	jalr	-788(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    8000485c:	00004517          	auipc	a0,0x4
    80004860:	ee450513          	addi	a0,a0,-284 # 80008740 <syscalls+0x220>
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	cdc080e7          	jalr	-804(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    8000486c:	00878693          	addi	a3,a5,8
    80004870:	068a                	slli	a3,a3,0x2
    80004872:	0001c717          	auipc	a4,0x1c
    80004876:	7ee70713          	addi	a4,a4,2030 # 80021060 <log>
    8000487a:	9736                	add	a4,a4,a3
    8000487c:	44d4                	lw	a3,12(s1)
    8000487e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004880:	faf609e3          	beq	a2,a5,80004832 <log_write+0x76>
  }
  release(&log.lock);
    80004884:	0001c517          	auipc	a0,0x1c
    80004888:	7dc50513          	addi	a0,a0,2012 # 80021060 <log>
    8000488c:	ffffc097          	auipc	ra,0xffffc
    80004890:	3fe080e7          	jalr	1022(ra) # 80000c8a <release>
}
    80004894:	60e2                	ld	ra,24(sp)
    80004896:	6442                	ld	s0,16(sp)
    80004898:	64a2                	ld	s1,8(sp)
    8000489a:	6902                	ld	s2,0(sp)
    8000489c:	6105                	addi	sp,sp,32
    8000489e:	8082                	ret

00000000800048a0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800048a0:	1101                	addi	sp,sp,-32
    800048a2:	ec06                	sd	ra,24(sp)
    800048a4:	e822                	sd	s0,16(sp)
    800048a6:	e426                	sd	s1,8(sp)
    800048a8:	e04a                	sd	s2,0(sp)
    800048aa:	1000                	addi	s0,sp,32
    800048ac:	84aa                	mv	s1,a0
    800048ae:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800048b0:	00004597          	auipc	a1,0x4
    800048b4:	eb058593          	addi	a1,a1,-336 # 80008760 <syscalls+0x240>
    800048b8:	0521                	addi	a0,a0,8
    800048ba:	ffffc097          	auipc	ra,0xffffc
    800048be:	28c080e7          	jalr	652(ra) # 80000b46 <initlock>
  lk->name = name;
    800048c2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800048c6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048ca:	0204a423          	sw	zero,40(s1)
}
    800048ce:	60e2                	ld	ra,24(sp)
    800048d0:	6442                	ld	s0,16(sp)
    800048d2:	64a2                	ld	s1,8(sp)
    800048d4:	6902                	ld	s2,0(sp)
    800048d6:	6105                	addi	sp,sp,32
    800048d8:	8082                	ret

00000000800048da <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800048da:	1101                	addi	sp,sp,-32
    800048dc:	ec06                	sd	ra,24(sp)
    800048de:	e822                	sd	s0,16(sp)
    800048e0:	e426                	sd	s1,8(sp)
    800048e2:	e04a                	sd	s2,0(sp)
    800048e4:	1000                	addi	s0,sp,32
    800048e6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048e8:	00850913          	addi	s2,a0,8
    800048ec:	854a                	mv	a0,s2
    800048ee:	ffffc097          	auipc	ra,0xffffc
    800048f2:	2e8080e7          	jalr	744(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800048f6:	409c                	lw	a5,0(s1)
    800048f8:	cb89                	beqz	a5,8000490a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800048fa:	85ca                	mv	a1,s2
    800048fc:	8526                	mv	a0,s1
    800048fe:	ffffe097          	auipc	ra,0xffffe
    80004902:	b6e080e7          	jalr	-1170(ra) # 8000246c <sleep>
  while (lk->locked) {
    80004906:	409c                	lw	a5,0(s1)
    80004908:	fbed                	bnez	a5,800048fa <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000490a:	4785                	li	a5,1
    8000490c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000490e:	ffffd097          	auipc	ra,0xffffd
    80004912:	17c080e7          	jalr	380(ra) # 80001a8a <myproc>
    80004916:	591c                	lw	a5,48(a0)
    80004918:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000491a:	854a                	mv	a0,s2
    8000491c:	ffffc097          	auipc	ra,0xffffc
    80004920:	36e080e7          	jalr	878(ra) # 80000c8a <release>
}
    80004924:	60e2                	ld	ra,24(sp)
    80004926:	6442                	ld	s0,16(sp)
    80004928:	64a2                	ld	s1,8(sp)
    8000492a:	6902                	ld	s2,0(sp)
    8000492c:	6105                	addi	sp,sp,32
    8000492e:	8082                	ret

0000000080004930 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004930:	1101                	addi	sp,sp,-32
    80004932:	ec06                	sd	ra,24(sp)
    80004934:	e822                	sd	s0,16(sp)
    80004936:	e426                	sd	s1,8(sp)
    80004938:	e04a                	sd	s2,0(sp)
    8000493a:	1000                	addi	s0,sp,32
    8000493c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000493e:	00850913          	addi	s2,a0,8
    80004942:	854a                	mv	a0,s2
    80004944:	ffffc097          	auipc	ra,0xffffc
    80004948:	292080e7          	jalr	658(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    8000494c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004950:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004954:	8526                	mv	a0,s1
    80004956:	ffffe097          	auipc	ra,0xffffe
    8000495a:	b7a080e7          	jalr	-1158(ra) # 800024d0 <wakeup>
  release(&lk->lk);
    8000495e:	854a                	mv	a0,s2
    80004960:	ffffc097          	auipc	ra,0xffffc
    80004964:	32a080e7          	jalr	810(ra) # 80000c8a <release>
}
    80004968:	60e2                	ld	ra,24(sp)
    8000496a:	6442                	ld	s0,16(sp)
    8000496c:	64a2                	ld	s1,8(sp)
    8000496e:	6902                	ld	s2,0(sp)
    80004970:	6105                	addi	sp,sp,32
    80004972:	8082                	ret

0000000080004974 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004974:	7179                	addi	sp,sp,-48
    80004976:	f406                	sd	ra,40(sp)
    80004978:	f022                	sd	s0,32(sp)
    8000497a:	ec26                	sd	s1,24(sp)
    8000497c:	e84a                	sd	s2,16(sp)
    8000497e:	e44e                	sd	s3,8(sp)
    80004980:	1800                	addi	s0,sp,48
    80004982:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004984:	00850913          	addi	s2,a0,8
    80004988:	854a                	mv	a0,s2
    8000498a:	ffffc097          	auipc	ra,0xffffc
    8000498e:	24c080e7          	jalr	588(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004992:	409c                	lw	a5,0(s1)
    80004994:	ef99                	bnez	a5,800049b2 <holdingsleep+0x3e>
    80004996:	4481                	li	s1,0
  release(&lk->lk);
    80004998:	854a                	mv	a0,s2
    8000499a:	ffffc097          	auipc	ra,0xffffc
    8000499e:	2f0080e7          	jalr	752(ra) # 80000c8a <release>
  return r;
}
    800049a2:	8526                	mv	a0,s1
    800049a4:	70a2                	ld	ra,40(sp)
    800049a6:	7402                	ld	s0,32(sp)
    800049a8:	64e2                	ld	s1,24(sp)
    800049aa:	6942                	ld	s2,16(sp)
    800049ac:	69a2                	ld	s3,8(sp)
    800049ae:	6145                	addi	sp,sp,48
    800049b0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800049b2:	0284a983          	lw	s3,40(s1)
    800049b6:	ffffd097          	auipc	ra,0xffffd
    800049ba:	0d4080e7          	jalr	212(ra) # 80001a8a <myproc>
    800049be:	5904                	lw	s1,48(a0)
    800049c0:	413484b3          	sub	s1,s1,s3
    800049c4:	0014b493          	seqz	s1,s1
    800049c8:	bfc1                	j	80004998 <holdingsleep+0x24>

00000000800049ca <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800049ca:	1141                	addi	sp,sp,-16
    800049cc:	e406                	sd	ra,8(sp)
    800049ce:	e022                	sd	s0,0(sp)
    800049d0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800049d2:	00004597          	auipc	a1,0x4
    800049d6:	d9e58593          	addi	a1,a1,-610 # 80008770 <syscalls+0x250>
    800049da:	0001c517          	auipc	a0,0x1c
    800049de:	7ce50513          	addi	a0,a0,1998 # 800211a8 <ftable>
    800049e2:	ffffc097          	auipc	ra,0xffffc
    800049e6:	164080e7          	jalr	356(ra) # 80000b46 <initlock>
}
    800049ea:	60a2                	ld	ra,8(sp)
    800049ec:	6402                	ld	s0,0(sp)
    800049ee:	0141                	addi	sp,sp,16
    800049f0:	8082                	ret

00000000800049f2 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800049f2:	1101                	addi	sp,sp,-32
    800049f4:	ec06                	sd	ra,24(sp)
    800049f6:	e822                	sd	s0,16(sp)
    800049f8:	e426                	sd	s1,8(sp)
    800049fa:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800049fc:	0001c517          	auipc	a0,0x1c
    80004a00:	7ac50513          	addi	a0,a0,1964 # 800211a8 <ftable>
    80004a04:	ffffc097          	auipc	ra,0xffffc
    80004a08:	1d2080e7          	jalr	466(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a0c:	0001c497          	auipc	s1,0x1c
    80004a10:	7b448493          	addi	s1,s1,1972 # 800211c0 <ftable+0x18>
    80004a14:	0001d717          	auipc	a4,0x1d
    80004a18:	74c70713          	addi	a4,a4,1868 # 80022160 <disk>
    if(f->ref == 0){
    80004a1c:	40dc                	lw	a5,4(s1)
    80004a1e:	cf99                	beqz	a5,80004a3c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004a20:	02848493          	addi	s1,s1,40
    80004a24:	fee49ce3          	bne	s1,a4,80004a1c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004a28:	0001c517          	auipc	a0,0x1c
    80004a2c:	78050513          	addi	a0,a0,1920 # 800211a8 <ftable>
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	25a080e7          	jalr	602(ra) # 80000c8a <release>
  return 0;
    80004a38:	4481                	li	s1,0
    80004a3a:	a819                	j	80004a50 <filealloc+0x5e>
      f->ref = 1;
    80004a3c:	4785                	li	a5,1
    80004a3e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004a40:	0001c517          	auipc	a0,0x1c
    80004a44:	76850513          	addi	a0,a0,1896 # 800211a8 <ftable>
    80004a48:	ffffc097          	auipc	ra,0xffffc
    80004a4c:	242080e7          	jalr	578(ra) # 80000c8a <release>
}
    80004a50:	8526                	mv	a0,s1
    80004a52:	60e2                	ld	ra,24(sp)
    80004a54:	6442                	ld	s0,16(sp)
    80004a56:	64a2                	ld	s1,8(sp)
    80004a58:	6105                	addi	sp,sp,32
    80004a5a:	8082                	ret

0000000080004a5c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004a5c:	1101                	addi	sp,sp,-32
    80004a5e:	ec06                	sd	ra,24(sp)
    80004a60:	e822                	sd	s0,16(sp)
    80004a62:	e426                	sd	s1,8(sp)
    80004a64:	1000                	addi	s0,sp,32
    80004a66:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004a68:	0001c517          	auipc	a0,0x1c
    80004a6c:	74050513          	addi	a0,a0,1856 # 800211a8 <ftable>
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	166080e7          	jalr	358(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004a78:	40dc                	lw	a5,4(s1)
    80004a7a:	02f05263          	blez	a5,80004a9e <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a7e:	2785                	addiw	a5,a5,1
    80004a80:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a82:	0001c517          	auipc	a0,0x1c
    80004a86:	72650513          	addi	a0,a0,1830 # 800211a8 <ftable>
    80004a8a:	ffffc097          	auipc	ra,0xffffc
    80004a8e:	200080e7          	jalr	512(ra) # 80000c8a <release>
  return f;
}
    80004a92:	8526                	mv	a0,s1
    80004a94:	60e2                	ld	ra,24(sp)
    80004a96:	6442                	ld	s0,16(sp)
    80004a98:	64a2                	ld	s1,8(sp)
    80004a9a:	6105                	addi	sp,sp,32
    80004a9c:	8082                	ret
    panic("filedup");
    80004a9e:	00004517          	auipc	a0,0x4
    80004aa2:	cda50513          	addi	a0,a0,-806 # 80008778 <syscalls+0x258>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	a9a080e7          	jalr	-1382(ra) # 80000540 <panic>

0000000080004aae <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004aae:	7139                	addi	sp,sp,-64
    80004ab0:	fc06                	sd	ra,56(sp)
    80004ab2:	f822                	sd	s0,48(sp)
    80004ab4:	f426                	sd	s1,40(sp)
    80004ab6:	f04a                	sd	s2,32(sp)
    80004ab8:	ec4e                	sd	s3,24(sp)
    80004aba:	e852                	sd	s4,16(sp)
    80004abc:	e456                	sd	s5,8(sp)
    80004abe:	0080                	addi	s0,sp,64
    80004ac0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004ac2:	0001c517          	auipc	a0,0x1c
    80004ac6:	6e650513          	addi	a0,a0,1766 # 800211a8 <ftable>
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	10c080e7          	jalr	268(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004ad2:	40dc                	lw	a5,4(s1)
    80004ad4:	06f05163          	blez	a5,80004b36 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004ad8:	37fd                	addiw	a5,a5,-1
    80004ada:	0007871b          	sext.w	a4,a5
    80004ade:	c0dc                	sw	a5,4(s1)
    80004ae0:	06e04363          	bgtz	a4,80004b46 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004ae4:	0004a903          	lw	s2,0(s1)
    80004ae8:	0094ca83          	lbu	s5,9(s1)
    80004aec:	0104ba03          	ld	s4,16(s1)
    80004af0:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004af4:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004af8:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004afc:	0001c517          	auipc	a0,0x1c
    80004b00:	6ac50513          	addi	a0,a0,1708 # 800211a8 <ftable>
    80004b04:	ffffc097          	auipc	ra,0xffffc
    80004b08:	186080e7          	jalr	390(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004b0c:	4785                	li	a5,1
    80004b0e:	04f90d63          	beq	s2,a5,80004b68 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004b12:	3979                	addiw	s2,s2,-2
    80004b14:	4785                	li	a5,1
    80004b16:	0527e063          	bltu	a5,s2,80004b56 <fileclose+0xa8>
    begin_op();
    80004b1a:	00000097          	auipc	ra,0x0
    80004b1e:	acc080e7          	jalr	-1332(ra) # 800045e6 <begin_op>
    iput(ff.ip);
    80004b22:	854e                	mv	a0,s3
    80004b24:	fffff097          	auipc	ra,0xfffff
    80004b28:	2b0080e7          	jalr	688(ra) # 80003dd4 <iput>
    end_op();
    80004b2c:	00000097          	auipc	ra,0x0
    80004b30:	b38080e7          	jalr	-1224(ra) # 80004664 <end_op>
    80004b34:	a00d                	j	80004b56 <fileclose+0xa8>
    panic("fileclose");
    80004b36:	00004517          	auipc	a0,0x4
    80004b3a:	c4a50513          	addi	a0,a0,-950 # 80008780 <syscalls+0x260>
    80004b3e:	ffffc097          	auipc	ra,0xffffc
    80004b42:	a02080e7          	jalr	-1534(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004b46:	0001c517          	auipc	a0,0x1c
    80004b4a:	66250513          	addi	a0,a0,1634 # 800211a8 <ftable>
    80004b4e:	ffffc097          	auipc	ra,0xffffc
    80004b52:	13c080e7          	jalr	316(ra) # 80000c8a <release>
  }
}
    80004b56:	70e2                	ld	ra,56(sp)
    80004b58:	7442                	ld	s0,48(sp)
    80004b5a:	74a2                	ld	s1,40(sp)
    80004b5c:	7902                	ld	s2,32(sp)
    80004b5e:	69e2                	ld	s3,24(sp)
    80004b60:	6a42                	ld	s4,16(sp)
    80004b62:	6aa2                	ld	s5,8(sp)
    80004b64:	6121                	addi	sp,sp,64
    80004b66:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004b68:	85d6                	mv	a1,s5
    80004b6a:	8552                	mv	a0,s4
    80004b6c:	00000097          	auipc	ra,0x0
    80004b70:	34c080e7          	jalr	844(ra) # 80004eb8 <pipeclose>
    80004b74:	b7cd                	j	80004b56 <fileclose+0xa8>

0000000080004b76 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004b76:	715d                	addi	sp,sp,-80
    80004b78:	e486                	sd	ra,72(sp)
    80004b7a:	e0a2                	sd	s0,64(sp)
    80004b7c:	fc26                	sd	s1,56(sp)
    80004b7e:	f84a                	sd	s2,48(sp)
    80004b80:	f44e                	sd	s3,40(sp)
    80004b82:	0880                	addi	s0,sp,80
    80004b84:	84aa                	mv	s1,a0
    80004b86:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b88:	ffffd097          	auipc	ra,0xffffd
    80004b8c:	f02080e7          	jalr	-254(ra) # 80001a8a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b90:	409c                	lw	a5,0(s1)
    80004b92:	37f9                	addiw	a5,a5,-2
    80004b94:	4705                	li	a4,1
    80004b96:	04f76763          	bltu	a4,a5,80004be4 <filestat+0x6e>
    80004b9a:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b9c:	6c88                	ld	a0,24(s1)
    80004b9e:	fffff097          	auipc	ra,0xfffff
    80004ba2:	07c080e7          	jalr	124(ra) # 80003c1a <ilock>
    stati(f->ip, &st);
    80004ba6:	fb840593          	addi	a1,s0,-72
    80004baa:	6c88                	ld	a0,24(s1)
    80004bac:	fffff097          	auipc	ra,0xfffff
    80004bb0:	2f8080e7          	jalr	760(ra) # 80003ea4 <stati>
    iunlock(f->ip);
    80004bb4:	6c88                	ld	a0,24(s1)
    80004bb6:	fffff097          	auipc	ra,0xfffff
    80004bba:	126080e7          	jalr	294(ra) # 80003cdc <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004bbe:	46e1                	li	a3,24
    80004bc0:	fb840613          	addi	a2,s0,-72
    80004bc4:	85ce                	mv	a1,s3
    80004bc6:	06093503          	ld	a0,96(s2)
    80004bca:	ffffd097          	auipc	ra,0xffffd
    80004bce:	aa2080e7          	jalr	-1374(ra) # 8000166c <copyout>
    80004bd2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004bd6:	60a6                	ld	ra,72(sp)
    80004bd8:	6406                	ld	s0,64(sp)
    80004bda:	74e2                	ld	s1,56(sp)
    80004bdc:	7942                	ld	s2,48(sp)
    80004bde:	79a2                	ld	s3,40(sp)
    80004be0:	6161                	addi	sp,sp,80
    80004be2:	8082                	ret
  return -1;
    80004be4:	557d                	li	a0,-1
    80004be6:	bfc5                	j	80004bd6 <filestat+0x60>

0000000080004be8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004be8:	7179                	addi	sp,sp,-48
    80004bea:	f406                	sd	ra,40(sp)
    80004bec:	f022                	sd	s0,32(sp)
    80004bee:	ec26                	sd	s1,24(sp)
    80004bf0:	e84a                	sd	s2,16(sp)
    80004bf2:	e44e                	sd	s3,8(sp)
    80004bf4:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004bf6:	00854783          	lbu	a5,8(a0)
    80004bfa:	c3d5                	beqz	a5,80004c9e <fileread+0xb6>
    80004bfc:	84aa                	mv	s1,a0
    80004bfe:	89ae                	mv	s3,a1
    80004c00:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c02:	411c                	lw	a5,0(a0)
    80004c04:	4705                	li	a4,1
    80004c06:	04e78963          	beq	a5,a4,80004c58 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c0a:	470d                	li	a4,3
    80004c0c:	04e78d63          	beq	a5,a4,80004c66 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c10:	4709                	li	a4,2
    80004c12:	06e79e63          	bne	a5,a4,80004c8e <fileread+0xa6>
    ilock(f->ip);
    80004c16:	6d08                	ld	a0,24(a0)
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	002080e7          	jalr	2(ra) # 80003c1a <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004c20:	874a                	mv	a4,s2
    80004c22:	5094                	lw	a3,32(s1)
    80004c24:	864e                	mv	a2,s3
    80004c26:	4585                	li	a1,1
    80004c28:	6c88                	ld	a0,24(s1)
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	2a4080e7          	jalr	676(ra) # 80003ece <readi>
    80004c32:	892a                	mv	s2,a0
    80004c34:	00a05563          	blez	a0,80004c3e <fileread+0x56>
      f->off += r;
    80004c38:	509c                	lw	a5,32(s1)
    80004c3a:	9fa9                	addw	a5,a5,a0
    80004c3c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004c3e:	6c88                	ld	a0,24(s1)
    80004c40:	fffff097          	auipc	ra,0xfffff
    80004c44:	09c080e7          	jalr	156(ra) # 80003cdc <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004c48:	854a                	mv	a0,s2
    80004c4a:	70a2                	ld	ra,40(sp)
    80004c4c:	7402                	ld	s0,32(sp)
    80004c4e:	64e2                	ld	s1,24(sp)
    80004c50:	6942                	ld	s2,16(sp)
    80004c52:	69a2                	ld	s3,8(sp)
    80004c54:	6145                	addi	sp,sp,48
    80004c56:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004c58:	6908                	ld	a0,16(a0)
    80004c5a:	00000097          	auipc	ra,0x0
    80004c5e:	3c6080e7          	jalr	966(ra) # 80005020 <piperead>
    80004c62:	892a                	mv	s2,a0
    80004c64:	b7d5                	j	80004c48 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004c66:	02451783          	lh	a5,36(a0)
    80004c6a:	03079693          	slli	a3,a5,0x30
    80004c6e:	92c1                	srli	a3,a3,0x30
    80004c70:	4725                	li	a4,9
    80004c72:	02d76863          	bltu	a4,a3,80004ca2 <fileread+0xba>
    80004c76:	0792                	slli	a5,a5,0x4
    80004c78:	0001c717          	auipc	a4,0x1c
    80004c7c:	49070713          	addi	a4,a4,1168 # 80021108 <devsw>
    80004c80:	97ba                	add	a5,a5,a4
    80004c82:	639c                	ld	a5,0(a5)
    80004c84:	c38d                	beqz	a5,80004ca6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c86:	4505                	li	a0,1
    80004c88:	9782                	jalr	a5
    80004c8a:	892a                	mv	s2,a0
    80004c8c:	bf75                	j	80004c48 <fileread+0x60>
    panic("fileread");
    80004c8e:	00004517          	auipc	a0,0x4
    80004c92:	b0250513          	addi	a0,a0,-1278 # 80008790 <syscalls+0x270>
    80004c96:	ffffc097          	auipc	ra,0xffffc
    80004c9a:	8aa080e7          	jalr	-1878(ra) # 80000540 <panic>
    return -1;
    80004c9e:	597d                	li	s2,-1
    80004ca0:	b765                	j	80004c48 <fileread+0x60>
      return -1;
    80004ca2:	597d                	li	s2,-1
    80004ca4:	b755                	j	80004c48 <fileread+0x60>
    80004ca6:	597d                	li	s2,-1
    80004ca8:	b745                	j	80004c48 <fileread+0x60>

0000000080004caa <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004caa:	715d                	addi	sp,sp,-80
    80004cac:	e486                	sd	ra,72(sp)
    80004cae:	e0a2                	sd	s0,64(sp)
    80004cb0:	fc26                	sd	s1,56(sp)
    80004cb2:	f84a                	sd	s2,48(sp)
    80004cb4:	f44e                	sd	s3,40(sp)
    80004cb6:	f052                	sd	s4,32(sp)
    80004cb8:	ec56                	sd	s5,24(sp)
    80004cba:	e85a                	sd	s6,16(sp)
    80004cbc:	e45e                	sd	s7,8(sp)
    80004cbe:	e062                	sd	s8,0(sp)
    80004cc0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004cc2:	00954783          	lbu	a5,9(a0)
    80004cc6:	10078663          	beqz	a5,80004dd2 <filewrite+0x128>
    80004cca:	892a                	mv	s2,a0
    80004ccc:	8b2e                	mv	s6,a1
    80004cce:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004cd0:	411c                	lw	a5,0(a0)
    80004cd2:	4705                	li	a4,1
    80004cd4:	02e78263          	beq	a5,a4,80004cf8 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004cd8:	470d                	li	a4,3
    80004cda:	02e78663          	beq	a5,a4,80004d06 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004cde:	4709                	li	a4,2
    80004ce0:	0ee79163          	bne	a5,a4,80004dc2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004ce4:	0ac05d63          	blez	a2,80004d9e <filewrite+0xf4>
    int i = 0;
    80004ce8:	4981                	li	s3,0
    80004cea:	6b85                	lui	s7,0x1
    80004cec:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004cf0:	6c05                	lui	s8,0x1
    80004cf2:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004cf6:	a861                	j	80004d8e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004cf8:	6908                	ld	a0,16(a0)
    80004cfa:	00000097          	auipc	ra,0x0
    80004cfe:	22e080e7          	jalr	558(ra) # 80004f28 <pipewrite>
    80004d02:	8a2a                	mv	s4,a0
    80004d04:	a045                	j	80004da4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004d06:	02451783          	lh	a5,36(a0)
    80004d0a:	03079693          	slli	a3,a5,0x30
    80004d0e:	92c1                	srli	a3,a3,0x30
    80004d10:	4725                	li	a4,9
    80004d12:	0cd76263          	bltu	a4,a3,80004dd6 <filewrite+0x12c>
    80004d16:	0792                	slli	a5,a5,0x4
    80004d18:	0001c717          	auipc	a4,0x1c
    80004d1c:	3f070713          	addi	a4,a4,1008 # 80021108 <devsw>
    80004d20:	97ba                	add	a5,a5,a4
    80004d22:	679c                	ld	a5,8(a5)
    80004d24:	cbdd                	beqz	a5,80004dda <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004d26:	4505                	li	a0,1
    80004d28:	9782                	jalr	a5
    80004d2a:	8a2a                	mv	s4,a0
    80004d2c:	a8a5                	j	80004da4 <filewrite+0xfa>
    80004d2e:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004d32:	00000097          	auipc	ra,0x0
    80004d36:	8b4080e7          	jalr	-1868(ra) # 800045e6 <begin_op>
      ilock(f->ip);
    80004d3a:	01893503          	ld	a0,24(s2)
    80004d3e:	fffff097          	auipc	ra,0xfffff
    80004d42:	edc080e7          	jalr	-292(ra) # 80003c1a <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004d46:	8756                	mv	a4,s5
    80004d48:	02092683          	lw	a3,32(s2)
    80004d4c:	01698633          	add	a2,s3,s6
    80004d50:	4585                	li	a1,1
    80004d52:	01893503          	ld	a0,24(s2)
    80004d56:	fffff097          	auipc	ra,0xfffff
    80004d5a:	270080e7          	jalr	624(ra) # 80003fc6 <writei>
    80004d5e:	84aa                	mv	s1,a0
    80004d60:	00a05763          	blez	a0,80004d6e <filewrite+0xc4>
        f->off += r;
    80004d64:	02092783          	lw	a5,32(s2)
    80004d68:	9fa9                	addw	a5,a5,a0
    80004d6a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004d6e:	01893503          	ld	a0,24(s2)
    80004d72:	fffff097          	auipc	ra,0xfffff
    80004d76:	f6a080e7          	jalr	-150(ra) # 80003cdc <iunlock>
      end_op();
    80004d7a:	00000097          	auipc	ra,0x0
    80004d7e:	8ea080e7          	jalr	-1814(ra) # 80004664 <end_op>

      if(r != n1){
    80004d82:	009a9f63          	bne	s5,s1,80004da0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004d86:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d8a:	0149db63          	bge	s3,s4,80004da0 <filewrite+0xf6>
      int n1 = n - i;
    80004d8e:	413a04bb          	subw	s1,s4,s3
    80004d92:	0004879b          	sext.w	a5,s1
    80004d96:	f8fbdce3          	bge	s7,a5,80004d2e <filewrite+0x84>
    80004d9a:	84e2                	mv	s1,s8
    80004d9c:	bf49                	j	80004d2e <filewrite+0x84>
    int i = 0;
    80004d9e:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004da0:	013a1f63          	bne	s4,s3,80004dbe <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004da4:	8552                	mv	a0,s4
    80004da6:	60a6                	ld	ra,72(sp)
    80004da8:	6406                	ld	s0,64(sp)
    80004daa:	74e2                	ld	s1,56(sp)
    80004dac:	7942                	ld	s2,48(sp)
    80004dae:	79a2                	ld	s3,40(sp)
    80004db0:	7a02                	ld	s4,32(sp)
    80004db2:	6ae2                	ld	s5,24(sp)
    80004db4:	6b42                	ld	s6,16(sp)
    80004db6:	6ba2                	ld	s7,8(sp)
    80004db8:	6c02                	ld	s8,0(sp)
    80004dba:	6161                	addi	sp,sp,80
    80004dbc:	8082                	ret
    ret = (i == n ? n : -1);
    80004dbe:	5a7d                	li	s4,-1
    80004dc0:	b7d5                	j	80004da4 <filewrite+0xfa>
    panic("filewrite");
    80004dc2:	00004517          	auipc	a0,0x4
    80004dc6:	9de50513          	addi	a0,a0,-1570 # 800087a0 <syscalls+0x280>
    80004dca:	ffffb097          	auipc	ra,0xffffb
    80004dce:	776080e7          	jalr	1910(ra) # 80000540 <panic>
    return -1;
    80004dd2:	5a7d                	li	s4,-1
    80004dd4:	bfc1                	j	80004da4 <filewrite+0xfa>
      return -1;
    80004dd6:	5a7d                	li	s4,-1
    80004dd8:	b7f1                	j	80004da4 <filewrite+0xfa>
    80004dda:	5a7d                	li	s4,-1
    80004ddc:	b7e1                	j	80004da4 <filewrite+0xfa>

0000000080004dde <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004dde:	7179                	addi	sp,sp,-48
    80004de0:	f406                	sd	ra,40(sp)
    80004de2:	f022                	sd	s0,32(sp)
    80004de4:	ec26                	sd	s1,24(sp)
    80004de6:	e84a                	sd	s2,16(sp)
    80004de8:	e44e                	sd	s3,8(sp)
    80004dea:	e052                	sd	s4,0(sp)
    80004dec:	1800                	addi	s0,sp,48
    80004dee:	84aa                	mv	s1,a0
    80004df0:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004df2:	0005b023          	sd	zero,0(a1)
    80004df6:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004dfa:	00000097          	auipc	ra,0x0
    80004dfe:	bf8080e7          	jalr	-1032(ra) # 800049f2 <filealloc>
    80004e02:	e088                	sd	a0,0(s1)
    80004e04:	c551                	beqz	a0,80004e90 <pipealloc+0xb2>
    80004e06:	00000097          	auipc	ra,0x0
    80004e0a:	bec080e7          	jalr	-1044(ra) # 800049f2 <filealloc>
    80004e0e:	00aa3023          	sd	a0,0(s4)
    80004e12:	c92d                	beqz	a0,80004e84 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	cd2080e7          	jalr	-814(ra) # 80000ae6 <kalloc>
    80004e1c:	892a                	mv	s2,a0
    80004e1e:	c125                	beqz	a0,80004e7e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004e20:	4985                	li	s3,1
    80004e22:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004e26:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004e2a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004e2e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004e32:	00004597          	auipc	a1,0x4
    80004e36:	97e58593          	addi	a1,a1,-1666 # 800087b0 <syscalls+0x290>
    80004e3a:	ffffc097          	auipc	ra,0xffffc
    80004e3e:	d0c080e7          	jalr	-756(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004e42:	609c                	ld	a5,0(s1)
    80004e44:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004e48:	609c                	ld	a5,0(s1)
    80004e4a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004e4e:	609c                	ld	a5,0(s1)
    80004e50:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e54:	609c                	ld	a5,0(s1)
    80004e56:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e5a:	000a3783          	ld	a5,0(s4)
    80004e5e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e62:	000a3783          	ld	a5,0(s4)
    80004e66:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e6a:	000a3783          	ld	a5,0(s4)
    80004e6e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e72:	000a3783          	ld	a5,0(s4)
    80004e76:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e7a:	4501                	li	a0,0
    80004e7c:	a025                	j	80004ea4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e7e:	6088                	ld	a0,0(s1)
    80004e80:	e501                	bnez	a0,80004e88 <pipealloc+0xaa>
    80004e82:	a039                	j	80004e90 <pipealloc+0xb2>
    80004e84:	6088                	ld	a0,0(s1)
    80004e86:	c51d                	beqz	a0,80004eb4 <pipealloc+0xd6>
    fileclose(*f0);
    80004e88:	00000097          	auipc	ra,0x0
    80004e8c:	c26080e7          	jalr	-986(ra) # 80004aae <fileclose>
  if(*f1)
    80004e90:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e94:	557d                	li	a0,-1
  if(*f1)
    80004e96:	c799                	beqz	a5,80004ea4 <pipealloc+0xc6>
    fileclose(*f1);
    80004e98:	853e                	mv	a0,a5
    80004e9a:	00000097          	auipc	ra,0x0
    80004e9e:	c14080e7          	jalr	-1004(ra) # 80004aae <fileclose>
  return -1;
    80004ea2:	557d                	li	a0,-1
}
    80004ea4:	70a2                	ld	ra,40(sp)
    80004ea6:	7402                	ld	s0,32(sp)
    80004ea8:	64e2                	ld	s1,24(sp)
    80004eaa:	6942                	ld	s2,16(sp)
    80004eac:	69a2                	ld	s3,8(sp)
    80004eae:	6a02                	ld	s4,0(sp)
    80004eb0:	6145                	addi	sp,sp,48
    80004eb2:	8082                	ret
  return -1;
    80004eb4:	557d                	li	a0,-1
    80004eb6:	b7fd                	j	80004ea4 <pipealloc+0xc6>

0000000080004eb8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004eb8:	1101                	addi	sp,sp,-32
    80004eba:	ec06                	sd	ra,24(sp)
    80004ebc:	e822                	sd	s0,16(sp)
    80004ebe:	e426                	sd	s1,8(sp)
    80004ec0:	e04a                	sd	s2,0(sp)
    80004ec2:	1000                	addi	s0,sp,32
    80004ec4:	84aa                	mv	s1,a0
    80004ec6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	d0e080e7          	jalr	-754(ra) # 80000bd6 <acquire>
  if(writable){
    80004ed0:	02090d63          	beqz	s2,80004f0a <pipeclose+0x52>
    pi->writeopen = 0;
    80004ed4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004ed8:	21848513          	addi	a0,s1,536
    80004edc:	ffffd097          	auipc	ra,0xffffd
    80004ee0:	5f4080e7          	jalr	1524(ra) # 800024d0 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ee4:	2204b783          	ld	a5,544(s1)
    80004ee8:	eb95                	bnez	a5,80004f1c <pipeclose+0x64>
    release(&pi->lock);
    80004eea:	8526                	mv	a0,s1
    80004eec:	ffffc097          	auipc	ra,0xffffc
    80004ef0:	d9e080e7          	jalr	-610(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004ef4:	8526                	mv	a0,s1
    80004ef6:	ffffc097          	auipc	ra,0xffffc
    80004efa:	af2080e7          	jalr	-1294(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004efe:	60e2                	ld	ra,24(sp)
    80004f00:	6442                	ld	s0,16(sp)
    80004f02:	64a2                	ld	s1,8(sp)
    80004f04:	6902                	ld	s2,0(sp)
    80004f06:	6105                	addi	sp,sp,32
    80004f08:	8082                	ret
    pi->readopen = 0;
    80004f0a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004f0e:	21c48513          	addi	a0,s1,540
    80004f12:	ffffd097          	auipc	ra,0xffffd
    80004f16:	5be080e7          	jalr	1470(ra) # 800024d0 <wakeup>
    80004f1a:	b7e9                	j	80004ee4 <pipeclose+0x2c>
    release(&pi->lock);
    80004f1c:	8526                	mv	a0,s1
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	d6c080e7          	jalr	-660(ra) # 80000c8a <release>
}
    80004f26:	bfe1                	j	80004efe <pipeclose+0x46>

0000000080004f28 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004f28:	711d                	addi	sp,sp,-96
    80004f2a:	ec86                	sd	ra,88(sp)
    80004f2c:	e8a2                	sd	s0,80(sp)
    80004f2e:	e4a6                	sd	s1,72(sp)
    80004f30:	e0ca                	sd	s2,64(sp)
    80004f32:	fc4e                	sd	s3,56(sp)
    80004f34:	f852                	sd	s4,48(sp)
    80004f36:	f456                	sd	s5,40(sp)
    80004f38:	f05a                	sd	s6,32(sp)
    80004f3a:	ec5e                	sd	s7,24(sp)
    80004f3c:	e862                	sd	s8,16(sp)
    80004f3e:	1080                	addi	s0,sp,96
    80004f40:	84aa                	mv	s1,a0
    80004f42:	8aae                	mv	s5,a1
    80004f44:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	b44080e7          	jalr	-1212(ra) # 80001a8a <myproc>
    80004f4e:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004f50:	8526                	mv	a0,s1
    80004f52:	ffffc097          	auipc	ra,0xffffc
    80004f56:	c84080e7          	jalr	-892(ra) # 80000bd6 <acquire>
  while(i < n){
    80004f5a:	0b405663          	blez	s4,80005006 <pipewrite+0xde>
  int i = 0;
    80004f5e:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f60:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004f62:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004f66:	21c48b93          	addi	s7,s1,540
    80004f6a:	a089                	j	80004fac <pipewrite+0x84>
      release(&pi->lock);
    80004f6c:	8526                	mv	a0,s1
    80004f6e:	ffffc097          	auipc	ra,0xffffc
    80004f72:	d1c080e7          	jalr	-740(ra) # 80000c8a <release>
      return -1;
    80004f76:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004f78:	854a                	mv	a0,s2
    80004f7a:	60e6                	ld	ra,88(sp)
    80004f7c:	6446                	ld	s0,80(sp)
    80004f7e:	64a6                	ld	s1,72(sp)
    80004f80:	6906                	ld	s2,64(sp)
    80004f82:	79e2                	ld	s3,56(sp)
    80004f84:	7a42                	ld	s4,48(sp)
    80004f86:	7aa2                	ld	s5,40(sp)
    80004f88:	7b02                	ld	s6,32(sp)
    80004f8a:	6be2                	ld	s7,24(sp)
    80004f8c:	6c42                	ld	s8,16(sp)
    80004f8e:	6125                	addi	sp,sp,96
    80004f90:	8082                	ret
      wakeup(&pi->nread);
    80004f92:	8562                	mv	a0,s8
    80004f94:	ffffd097          	auipc	ra,0xffffd
    80004f98:	53c080e7          	jalr	1340(ra) # 800024d0 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f9c:	85a6                	mv	a1,s1
    80004f9e:	855e                	mv	a0,s7
    80004fa0:	ffffd097          	auipc	ra,0xffffd
    80004fa4:	4cc080e7          	jalr	1228(ra) # 8000246c <sleep>
  while(i < n){
    80004fa8:	07495063          	bge	s2,s4,80005008 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004fac:	2204a783          	lw	a5,544(s1)
    80004fb0:	dfd5                	beqz	a5,80004f6c <pipewrite+0x44>
    80004fb2:	854e                	mv	a0,s3
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	760080e7          	jalr	1888(ra) # 80002714 <killed>
    80004fbc:	f945                	bnez	a0,80004f6c <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004fbe:	2184a783          	lw	a5,536(s1)
    80004fc2:	21c4a703          	lw	a4,540(s1)
    80004fc6:	2007879b          	addiw	a5,a5,512
    80004fca:	fcf704e3          	beq	a4,a5,80004f92 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004fce:	4685                	li	a3,1
    80004fd0:	01590633          	add	a2,s2,s5
    80004fd4:	faf40593          	addi	a1,s0,-81
    80004fd8:	0609b503          	ld	a0,96(s3)
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	71c080e7          	jalr	1820(ra) # 800016f8 <copyin>
    80004fe4:	03650263          	beq	a0,s6,80005008 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004fe8:	21c4a783          	lw	a5,540(s1)
    80004fec:	0017871b          	addiw	a4,a5,1
    80004ff0:	20e4ae23          	sw	a4,540(s1)
    80004ff4:	1ff7f793          	andi	a5,a5,511
    80004ff8:	97a6                	add	a5,a5,s1
    80004ffa:	faf44703          	lbu	a4,-81(s0)
    80004ffe:	00e78c23          	sb	a4,24(a5)
      i++;
    80005002:	2905                	addiw	s2,s2,1
    80005004:	b755                	j	80004fa8 <pipewrite+0x80>
  int i = 0;
    80005006:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005008:	21848513          	addi	a0,s1,536
    8000500c:	ffffd097          	auipc	ra,0xffffd
    80005010:	4c4080e7          	jalr	1220(ra) # 800024d0 <wakeup>
  release(&pi->lock);
    80005014:	8526                	mv	a0,s1
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	c74080e7          	jalr	-908(ra) # 80000c8a <release>
  return i;
    8000501e:	bfa9                	j	80004f78 <pipewrite+0x50>

0000000080005020 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005020:	715d                	addi	sp,sp,-80
    80005022:	e486                	sd	ra,72(sp)
    80005024:	e0a2                	sd	s0,64(sp)
    80005026:	fc26                	sd	s1,56(sp)
    80005028:	f84a                	sd	s2,48(sp)
    8000502a:	f44e                	sd	s3,40(sp)
    8000502c:	f052                	sd	s4,32(sp)
    8000502e:	ec56                	sd	s5,24(sp)
    80005030:	e85a                	sd	s6,16(sp)
    80005032:	0880                	addi	s0,sp,80
    80005034:	84aa                	mv	s1,a0
    80005036:	892e                	mv	s2,a1
    80005038:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000503a:	ffffd097          	auipc	ra,0xffffd
    8000503e:	a50080e7          	jalr	-1456(ra) # 80001a8a <myproc>
    80005042:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005044:	8526                	mv	a0,s1
    80005046:	ffffc097          	auipc	ra,0xffffc
    8000504a:	b90080e7          	jalr	-1136(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000504e:	2184a703          	lw	a4,536(s1)
    80005052:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005056:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000505a:	02f71763          	bne	a4,a5,80005088 <piperead+0x68>
    8000505e:	2244a783          	lw	a5,548(s1)
    80005062:	c39d                	beqz	a5,80005088 <piperead+0x68>
    if(killed(pr)){
    80005064:	8552                	mv	a0,s4
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	6ae080e7          	jalr	1710(ra) # 80002714 <killed>
    8000506e:	e949                	bnez	a0,80005100 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005070:	85a6                	mv	a1,s1
    80005072:	854e                	mv	a0,s3
    80005074:	ffffd097          	auipc	ra,0xffffd
    80005078:	3f8080e7          	jalr	1016(ra) # 8000246c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000507c:	2184a703          	lw	a4,536(s1)
    80005080:	21c4a783          	lw	a5,540(s1)
    80005084:	fcf70de3          	beq	a4,a5,8000505e <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005088:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000508a:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000508c:	05505463          	blez	s5,800050d4 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005090:	2184a783          	lw	a5,536(s1)
    80005094:	21c4a703          	lw	a4,540(s1)
    80005098:	02f70e63          	beq	a4,a5,800050d4 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000509c:	0017871b          	addiw	a4,a5,1
    800050a0:	20e4ac23          	sw	a4,536(s1)
    800050a4:	1ff7f793          	andi	a5,a5,511
    800050a8:	97a6                	add	a5,a5,s1
    800050aa:	0187c783          	lbu	a5,24(a5)
    800050ae:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800050b2:	4685                	li	a3,1
    800050b4:	fbf40613          	addi	a2,s0,-65
    800050b8:	85ca                	mv	a1,s2
    800050ba:	060a3503          	ld	a0,96(s4)
    800050be:	ffffc097          	auipc	ra,0xffffc
    800050c2:	5ae080e7          	jalr	1454(ra) # 8000166c <copyout>
    800050c6:	01650763          	beq	a0,s6,800050d4 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ca:	2985                	addiw	s3,s3,1
    800050cc:	0905                	addi	s2,s2,1
    800050ce:	fd3a91e3          	bne	s5,s3,80005090 <piperead+0x70>
    800050d2:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050d4:	21c48513          	addi	a0,s1,540
    800050d8:	ffffd097          	auipc	ra,0xffffd
    800050dc:	3f8080e7          	jalr	1016(ra) # 800024d0 <wakeup>
  release(&pi->lock);
    800050e0:	8526                	mv	a0,s1
    800050e2:	ffffc097          	auipc	ra,0xffffc
    800050e6:	ba8080e7          	jalr	-1112(ra) # 80000c8a <release>
  return i;
}
    800050ea:	854e                	mv	a0,s3
    800050ec:	60a6                	ld	ra,72(sp)
    800050ee:	6406                	ld	s0,64(sp)
    800050f0:	74e2                	ld	s1,56(sp)
    800050f2:	7942                	ld	s2,48(sp)
    800050f4:	79a2                	ld	s3,40(sp)
    800050f6:	7a02                	ld	s4,32(sp)
    800050f8:	6ae2                	ld	s5,24(sp)
    800050fa:	6b42                	ld	s6,16(sp)
    800050fc:	6161                	addi	sp,sp,80
    800050fe:	8082                	ret
      release(&pi->lock);
    80005100:	8526                	mv	a0,s1
    80005102:	ffffc097          	auipc	ra,0xffffc
    80005106:	b88080e7          	jalr	-1144(ra) # 80000c8a <release>
      return -1;
    8000510a:	59fd                	li	s3,-1
    8000510c:	bff9                	j	800050ea <piperead+0xca>

000000008000510e <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000510e:	1141                	addi	sp,sp,-16
    80005110:	e422                	sd	s0,8(sp)
    80005112:	0800                	addi	s0,sp,16
    80005114:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005116:	8905                	andi	a0,a0,1
    80005118:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    8000511a:	8b89                	andi	a5,a5,2
    8000511c:	c399                	beqz	a5,80005122 <flags2perm+0x14>
      perm |= PTE_W;
    8000511e:	00456513          	ori	a0,a0,4
    return perm;
}
    80005122:	6422                	ld	s0,8(sp)
    80005124:	0141                	addi	sp,sp,16
    80005126:	8082                	ret

0000000080005128 <exec>:

int
exec(char *path, char **argv)
{
    80005128:	de010113          	addi	sp,sp,-544
    8000512c:	20113c23          	sd	ra,536(sp)
    80005130:	20813823          	sd	s0,528(sp)
    80005134:	20913423          	sd	s1,520(sp)
    80005138:	21213023          	sd	s2,512(sp)
    8000513c:	ffce                	sd	s3,504(sp)
    8000513e:	fbd2                	sd	s4,496(sp)
    80005140:	f7d6                	sd	s5,488(sp)
    80005142:	f3da                	sd	s6,480(sp)
    80005144:	efde                	sd	s7,472(sp)
    80005146:	ebe2                	sd	s8,464(sp)
    80005148:	e7e6                	sd	s9,456(sp)
    8000514a:	e3ea                	sd	s10,448(sp)
    8000514c:	ff6e                	sd	s11,440(sp)
    8000514e:	1400                	addi	s0,sp,544
    80005150:	892a                	mv	s2,a0
    80005152:	dea43423          	sd	a0,-536(s0)
    80005156:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000515a:	ffffd097          	auipc	ra,0xffffd
    8000515e:	930080e7          	jalr	-1744(ra) # 80001a8a <myproc>
    80005162:	84aa                	mv	s1,a0

  begin_op();
    80005164:	fffff097          	auipc	ra,0xfffff
    80005168:	482080e7          	jalr	1154(ra) # 800045e6 <begin_op>

  if((ip = namei(path)) == 0){
    8000516c:	854a                	mv	a0,s2
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	258080e7          	jalr	600(ra) # 800043c6 <namei>
    80005176:	c93d                	beqz	a0,800051ec <exec+0xc4>
    80005178:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000517a:	fffff097          	auipc	ra,0xfffff
    8000517e:	aa0080e7          	jalr	-1376(ra) # 80003c1a <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005182:	04000713          	li	a4,64
    80005186:	4681                	li	a3,0
    80005188:	e5040613          	addi	a2,s0,-432
    8000518c:	4581                	li	a1,0
    8000518e:	8556                	mv	a0,s5
    80005190:	fffff097          	auipc	ra,0xfffff
    80005194:	d3e080e7          	jalr	-706(ra) # 80003ece <readi>
    80005198:	04000793          	li	a5,64
    8000519c:	00f51a63          	bne	a0,a5,800051b0 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800051a0:	e5042703          	lw	a4,-432(s0)
    800051a4:	464c47b7          	lui	a5,0x464c4
    800051a8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800051ac:	04f70663          	beq	a4,a5,800051f8 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800051b0:	8556                	mv	a0,s5
    800051b2:	fffff097          	auipc	ra,0xfffff
    800051b6:	cca080e7          	jalr	-822(ra) # 80003e7c <iunlockput>
    end_op();
    800051ba:	fffff097          	auipc	ra,0xfffff
    800051be:	4aa080e7          	jalr	1194(ra) # 80004664 <end_op>
  }
  return -1;
    800051c2:	557d                	li	a0,-1
}
    800051c4:	21813083          	ld	ra,536(sp)
    800051c8:	21013403          	ld	s0,528(sp)
    800051cc:	20813483          	ld	s1,520(sp)
    800051d0:	20013903          	ld	s2,512(sp)
    800051d4:	79fe                	ld	s3,504(sp)
    800051d6:	7a5e                	ld	s4,496(sp)
    800051d8:	7abe                	ld	s5,488(sp)
    800051da:	7b1e                	ld	s6,480(sp)
    800051dc:	6bfe                	ld	s7,472(sp)
    800051de:	6c5e                	ld	s8,464(sp)
    800051e0:	6cbe                	ld	s9,456(sp)
    800051e2:	6d1e                	ld	s10,448(sp)
    800051e4:	7dfa                	ld	s11,440(sp)
    800051e6:	22010113          	addi	sp,sp,544
    800051ea:	8082                	ret
    end_op();
    800051ec:	fffff097          	auipc	ra,0xfffff
    800051f0:	478080e7          	jalr	1144(ra) # 80004664 <end_op>
    return -1;
    800051f4:	557d                	li	a0,-1
    800051f6:	b7f9                	j	800051c4 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800051f8:	8526                	mv	a0,s1
    800051fa:	ffffd097          	auipc	ra,0xffffd
    800051fe:	954080e7          	jalr	-1708(ra) # 80001b4e <proc_pagetable>
    80005202:	8b2a                	mv	s6,a0
    80005204:	d555                	beqz	a0,800051b0 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005206:	e7042783          	lw	a5,-400(s0)
    8000520a:	e8845703          	lhu	a4,-376(s0)
    8000520e:	c735                	beqz	a4,8000527a <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005210:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005212:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005216:	6a05                	lui	s4,0x1
    80005218:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    8000521c:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005220:	6d85                	lui	s11,0x1
    80005222:	7d7d                	lui	s10,0xfffff
    80005224:	ac3d                	j	80005462 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005226:	00003517          	auipc	a0,0x3
    8000522a:	59250513          	addi	a0,a0,1426 # 800087b8 <syscalls+0x298>
    8000522e:	ffffb097          	auipc	ra,0xffffb
    80005232:	312080e7          	jalr	786(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005236:	874a                	mv	a4,s2
    80005238:	009c86bb          	addw	a3,s9,s1
    8000523c:	4581                	li	a1,0
    8000523e:	8556                	mv	a0,s5
    80005240:	fffff097          	auipc	ra,0xfffff
    80005244:	c8e080e7          	jalr	-882(ra) # 80003ece <readi>
    80005248:	2501                	sext.w	a0,a0
    8000524a:	1aa91963          	bne	s2,a0,800053fc <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    8000524e:	009d84bb          	addw	s1,s11,s1
    80005252:	013d09bb          	addw	s3,s10,s3
    80005256:	1f74f663          	bgeu	s1,s7,80005442 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    8000525a:	02049593          	slli	a1,s1,0x20
    8000525e:	9181                	srli	a1,a1,0x20
    80005260:	95e2                	add	a1,a1,s8
    80005262:	855a                	mv	a0,s6
    80005264:	ffffc097          	auipc	ra,0xffffc
    80005268:	df8080e7          	jalr	-520(ra) # 8000105c <walkaddr>
    8000526c:	862a                	mv	a2,a0
    if(pa == 0)
    8000526e:	dd45                	beqz	a0,80005226 <exec+0xfe>
      n = PGSIZE;
    80005270:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005272:	fd49f2e3          	bgeu	s3,s4,80005236 <exec+0x10e>
      n = sz - i;
    80005276:	894e                	mv	s2,s3
    80005278:	bf7d                	j	80005236 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000527a:	4901                	li	s2,0
  iunlockput(ip);
    8000527c:	8556                	mv	a0,s5
    8000527e:	fffff097          	auipc	ra,0xfffff
    80005282:	bfe080e7          	jalr	-1026(ra) # 80003e7c <iunlockput>
  end_op();
    80005286:	fffff097          	auipc	ra,0xfffff
    8000528a:	3de080e7          	jalr	990(ra) # 80004664 <end_op>
  p = myproc();
    8000528e:	ffffc097          	auipc	ra,0xffffc
    80005292:	7fc080e7          	jalr	2044(ra) # 80001a8a <myproc>
    80005296:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005298:	05853d03          	ld	s10,88(a0)
  sz = PGROUNDUP(sz);
    8000529c:	6785                	lui	a5,0x1
    8000529e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800052a0:	97ca                	add	a5,a5,s2
    800052a2:	777d                	lui	a4,0xfffff
    800052a4:	8ff9                	and	a5,a5,a4
    800052a6:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052aa:	4691                	li	a3,4
    800052ac:	6609                	lui	a2,0x2
    800052ae:	963e                	add	a2,a2,a5
    800052b0:	85be                	mv	a1,a5
    800052b2:	855a                	mv	a0,s6
    800052b4:	ffffc097          	auipc	ra,0xffffc
    800052b8:	15c080e7          	jalr	348(ra) # 80001410 <uvmalloc>
    800052bc:	8c2a                	mv	s8,a0
  ip = 0;
    800052be:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800052c0:	12050e63          	beqz	a0,800053fc <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    800052c4:	75f9                	lui	a1,0xffffe
    800052c6:	95aa                	add	a1,a1,a0
    800052c8:	855a                	mv	a0,s6
    800052ca:	ffffc097          	auipc	ra,0xffffc
    800052ce:	370080e7          	jalr	880(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800052d2:	7afd                	lui	s5,0xfffff
    800052d4:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800052d6:	df043783          	ld	a5,-528(s0)
    800052da:	6388                	ld	a0,0(a5)
    800052dc:	c925                	beqz	a0,8000534c <exec+0x224>
    800052de:	e9040993          	addi	s3,s0,-368
    800052e2:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800052e6:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800052e8:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800052ea:	ffffc097          	auipc	ra,0xffffc
    800052ee:	b64080e7          	jalr	-1180(ra) # 80000e4e <strlen>
    800052f2:	0015079b          	addiw	a5,a0,1
    800052f6:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052fa:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800052fe:	13596663          	bltu	s2,s5,8000542a <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005302:	df043d83          	ld	s11,-528(s0)
    80005306:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    8000530a:	8552                	mv	a0,s4
    8000530c:	ffffc097          	auipc	ra,0xffffc
    80005310:	b42080e7          	jalr	-1214(ra) # 80000e4e <strlen>
    80005314:	0015069b          	addiw	a3,a0,1
    80005318:	8652                	mv	a2,s4
    8000531a:	85ca                	mv	a1,s2
    8000531c:	855a                	mv	a0,s6
    8000531e:	ffffc097          	auipc	ra,0xffffc
    80005322:	34e080e7          	jalr	846(ra) # 8000166c <copyout>
    80005326:	10054663          	bltz	a0,80005432 <exec+0x30a>
    ustack[argc] = sp;
    8000532a:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000532e:	0485                	addi	s1,s1,1
    80005330:	008d8793          	addi	a5,s11,8
    80005334:	def43823          	sd	a5,-528(s0)
    80005338:	008db503          	ld	a0,8(s11)
    8000533c:	c911                	beqz	a0,80005350 <exec+0x228>
    if(argc >= MAXARG)
    8000533e:	09a1                	addi	s3,s3,8
    80005340:	fb3c95e3          	bne	s9,s3,800052ea <exec+0x1c2>
  sz = sz1;
    80005344:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005348:	4a81                	li	s5,0
    8000534a:	a84d                	j	800053fc <exec+0x2d4>
  sp = sz;
    8000534c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    8000534e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005350:	00349793          	slli	a5,s1,0x3
    80005354:	f9078793          	addi	a5,a5,-112
    80005358:	97a2                	add	a5,a5,s0
    8000535a:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    8000535e:	00148693          	addi	a3,s1,1
    80005362:	068e                	slli	a3,a3,0x3
    80005364:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005368:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000536c:	01597663          	bgeu	s2,s5,80005378 <exec+0x250>
  sz = sz1;
    80005370:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005374:	4a81                	li	s5,0
    80005376:	a059                	j	800053fc <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005378:	e9040613          	addi	a2,s0,-368
    8000537c:	85ca                	mv	a1,s2
    8000537e:	855a                	mv	a0,s6
    80005380:	ffffc097          	auipc	ra,0xffffc
    80005384:	2ec080e7          	jalr	748(ra) # 8000166c <copyout>
    80005388:	0a054963          	bltz	a0,8000543a <exec+0x312>
  p->trapframe->a1 = sp;
    8000538c:	068bb783          	ld	a5,104(s7)
    80005390:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005394:	de843783          	ld	a5,-536(s0)
    80005398:	0007c703          	lbu	a4,0(a5)
    8000539c:	cf11                	beqz	a4,800053b8 <exec+0x290>
    8000539e:	0785                	addi	a5,a5,1
    if(*s == '/')
    800053a0:	02f00693          	li	a3,47
    800053a4:	a039                	j	800053b2 <exec+0x28a>
      last = s+1;
    800053a6:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    800053aa:	0785                	addi	a5,a5,1
    800053ac:	fff7c703          	lbu	a4,-1(a5)
    800053b0:	c701                	beqz	a4,800053b8 <exec+0x290>
    if(*s == '/')
    800053b2:	fed71ce3          	bne	a4,a3,800053aa <exec+0x282>
    800053b6:	bfc5                	j	800053a6 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    800053b8:	4641                	li	a2,16
    800053ba:	de843583          	ld	a1,-536(s0)
    800053be:	168b8513          	addi	a0,s7,360
    800053c2:	ffffc097          	auipc	ra,0xffffc
    800053c6:	a5a080e7          	jalr	-1446(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800053ca:	060bb503          	ld	a0,96(s7)
  p->pagetable = pagetable;
    800053ce:	076bb023          	sd	s6,96(s7)
  p->sz = sz;
    800053d2:	058bbc23          	sd	s8,88(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800053d6:	068bb783          	ld	a5,104(s7)
    800053da:	e6843703          	ld	a4,-408(s0)
    800053de:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800053e0:	068bb783          	ld	a5,104(s7)
    800053e4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053e8:	85ea                	mv	a1,s10
    800053ea:	ffffd097          	auipc	ra,0xffffd
    800053ee:	800080e7          	jalr	-2048(ra) # 80001bea <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053f2:	0004851b          	sext.w	a0,s1
    800053f6:	b3f9                	j	800051c4 <exec+0x9c>
    800053f8:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800053fc:	df843583          	ld	a1,-520(s0)
    80005400:	855a                	mv	a0,s6
    80005402:	ffffc097          	auipc	ra,0xffffc
    80005406:	7e8080e7          	jalr	2024(ra) # 80001bea <proc_freepagetable>
  if(ip){
    8000540a:	da0a93e3          	bnez	s5,800051b0 <exec+0x88>
  return -1;
    8000540e:	557d                	li	a0,-1
    80005410:	bb55                	j	800051c4 <exec+0x9c>
    80005412:	df243c23          	sd	s2,-520(s0)
    80005416:	b7dd                	j	800053fc <exec+0x2d4>
    80005418:	df243c23          	sd	s2,-520(s0)
    8000541c:	b7c5                	j	800053fc <exec+0x2d4>
    8000541e:	df243c23          	sd	s2,-520(s0)
    80005422:	bfe9                	j	800053fc <exec+0x2d4>
    80005424:	df243c23          	sd	s2,-520(s0)
    80005428:	bfd1                	j	800053fc <exec+0x2d4>
  sz = sz1;
    8000542a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000542e:	4a81                	li	s5,0
    80005430:	b7f1                	j	800053fc <exec+0x2d4>
  sz = sz1;
    80005432:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005436:	4a81                	li	s5,0
    80005438:	b7d1                	j	800053fc <exec+0x2d4>
  sz = sz1;
    8000543a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000543e:	4a81                	li	s5,0
    80005440:	bf75                	j	800053fc <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005442:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005446:	e0843783          	ld	a5,-504(s0)
    8000544a:	0017869b          	addiw	a3,a5,1
    8000544e:	e0d43423          	sd	a3,-504(s0)
    80005452:	e0043783          	ld	a5,-512(s0)
    80005456:	0387879b          	addiw	a5,a5,56
    8000545a:	e8845703          	lhu	a4,-376(s0)
    8000545e:	e0e6dfe3          	bge	a3,a4,8000527c <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005462:	2781                	sext.w	a5,a5
    80005464:	e0f43023          	sd	a5,-512(s0)
    80005468:	03800713          	li	a4,56
    8000546c:	86be                	mv	a3,a5
    8000546e:	e1840613          	addi	a2,s0,-488
    80005472:	4581                	li	a1,0
    80005474:	8556                	mv	a0,s5
    80005476:	fffff097          	auipc	ra,0xfffff
    8000547a:	a58080e7          	jalr	-1448(ra) # 80003ece <readi>
    8000547e:	03800793          	li	a5,56
    80005482:	f6f51be3          	bne	a0,a5,800053f8 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005486:	e1842783          	lw	a5,-488(s0)
    8000548a:	4705                	li	a4,1
    8000548c:	fae79de3          	bne	a5,a4,80005446 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005490:	e4043483          	ld	s1,-448(s0)
    80005494:	e3843783          	ld	a5,-456(s0)
    80005498:	f6f4ede3          	bltu	s1,a5,80005412 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000549c:	e2843783          	ld	a5,-472(s0)
    800054a0:	94be                	add	s1,s1,a5
    800054a2:	f6f4ebe3          	bltu	s1,a5,80005418 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    800054a6:	de043703          	ld	a4,-544(s0)
    800054aa:	8ff9                	and	a5,a5,a4
    800054ac:	fbad                	bnez	a5,8000541e <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800054ae:	e1c42503          	lw	a0,-484(s0)
    800054b2:	00000097          	auipc	ra,0x0
    800054b6:	c5c080e7          	jalr	-932(ra) # 8000510e <flags2perm>
    800054ba:	86aa                	mv	a3,a0
    800054bc:	8626                	mv	a2,s1
    800054be:	85ca                	mv	a1,s2
    800054c0:	855a                	mv	a0,s6
    800054c2:	ffffc097          	auipc	ra,0xffffc
    800054c6:	f4e080e7          	jalr	-178(ra) # 80001410 <uvmalloc>
    800054ca:	dea43c23          	sd	a0,-520(s0)
    800054ce:	d939                	beqz	a0,80005424 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800054d0:	e2843c03          	ld	s8,-472(s0)
    800054d4:	e2042c83          	lw	s9,-480(s0)
    800054d8:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800054dc:	f60b83e3          	beqz	s7,80005442 <exec+0x31a>
    800054e0:	89de                	mv	s3,s7
    800054e2:	4481                	li	s1,0
    800054e4:	bb9d                	j	8000525a <exec+0x132>

00000000800054e6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800054e6:	7179                	addi	sp,sp,-48
    800054e8:	f406                	sd	ra,40(sp)
    800054ea:	f022                	sd	s0,32(sp)
    800054ec:	ec26                	sd	s1,24(sp)
    800054ee:	e84a                	sd	s2,16(sp)
    800054f0:	1800                	addi	s0,sp,48
    800054f2:	892e                	mv	s2,a1
    800054f4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800054f6:	fdc40593          	addi	a1,s0,-36
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	b26080e7          	jalr	-1242(ra) # 80003020 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005502:	fdc42703          	lw	a4,-36(s0)
    80005506:	47bd                	li	a5,15
    80005508:	02e7eb63          	bltu	a5,a4,8000553e <argfd+0x58>
    8000550c:	ffffc097          	auipc	ra,0xffffc
    80005510:	57e080e7          	jalr	1406(ra) # 80001a8a <myproc>
    80005514:	fdc42703          	lw	a4,-36(s0)
    80005518:	01c70793          	addi	a5,a4,28 # fffffffffffff01c <end+0xffffffff7ffdcd7c>
    8000551c:	078e                	slli	a5,a5,0x3
    8000551e:	953e                	add	a0,a0,a5
    80005520:	611c                	ld	a5,0(a0)
    80005522:	c385                	beqz	a5,80005542 <argfd+0x5c>
    return -1;
  if(pfd)
    80005524:	00090463          	beqz	s2,8000552c <argfd+0x46>
    *pfd = fd;
    80005528:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000552c:	4501                	li	a0,0
  if(pf)
    8000552e:	c091                	beqz	s1,80005532 <argfd+0x4c>
    *pf = f;
    80005530:	e09c                	sd	a5,0(s1)
}
    80005532:	70a2                	ld	ra,40(sp)
    80005534:	7402                	ld	s0,32(sp)
    80005536:	64e2                	ld	s1,24(sp)
    80005538:	6942                	ld	s2,16(sp)
    8000553a:	6145                	addi	sp,sp,48
    8000553c:	8082                	ret
    return -1;
    8000553e:	557d                	li	a0,-1
    80005540:	bfcd                	j	80005532 <argfd+0x4c>
    80005542:	557d                	li	a0,-1
    80005544:	b7fd                	j	80005532 <argfd+0x4c>

0000000080005546 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005546:	1101                	addi	sp,sp,-32
    80005548:	ec06                	sd	ra,24(sp)
    8000554a:	e822                	sd	s0,16(sp)
    8000554c:	e426                	sd	s1,8(sp)
    8000554e:	1000                	addi	s0,sp,32
    80005550:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005552:	ffffc097          	auipc	ra,0xffffc
    80005556:	538080e7          	jalr	1336(ra) # 80001a8a <myproc>
    8000555a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000555c:	0e050793          	addi	a5,a0,224
    80005560:	4501                	li	a0,0
    80005562:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005564:	6398                	ld	a4,0(a5)
    80005566:	cb19                	beqz	a4,8000557c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005568:	2505                	addiw	a0,a0,1
    8000556a:	07a1                	addi	a5,a5,8
    8000556c:	fed51ce3          	bne	a0,a3,80005564 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005570:	557d                	li	a0,-1
}
    80005572:	60e2                	ld	ra,24(sp)
    80005574:	6442                	ld	s0,16(sp)
    80005576:	64a2                	ld	s1,8(sp)
    80005578:	6105                	addi	sp,sp,32
    8000557a:	8082                	ret
      p->ofile[fd] = f;
    8000557c:	01c50793          	addi	a5,a0,28
    80005580:	078e                	slli	a5,a5,0x3
    80005582:	963e                	add	a2,a2,a5
    80005584:	e204                	sd	s1,0(a2)
      return fd;
    80005586:	b7f5                	j	80005572 <fdalloc+0x2c>

0000000080005588 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005588:	715d                	addi	sp,sp,-80
    8000558a:	e486                	sd	ra,72(sp)
    8000558c:	e0a2                	sd	s0,64(sp)
    8000558e:	fc26                	sd	s1,56(sp)
    80005590:	f84a                	sd	s2,48(sp)
    80005592:	f44e                	sd	s3,40(sp)
    80005594:	f052                	sd	s4,32(sp)
    80005596:	ec56                	sd	s5,24(sp)
    80005598:	e85a                	sd	s6,16(sp)
    8000559a:	0880                	addi	s0,sp,80
    8000559c:	8b2e                	mv	s6,a1
    8000559e:	89b2                	mv	s3,a2
    800055a0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800055a2:	fb040593          	addi	a1,s0,-80
    800055a6:	fffff097          	auipc	ra,0xfffff
    800055aa:	e3e080e7          	jalr	-450(ra) # 800043e4 <nameiparent>
    800055ae:	84aa                	mv	s1,a0
    800055b0:	14050f63          	beqz	a0,8000570e <create+0x186>
    return 0;

  ilock(dp);
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	666080e7          	jalr	1638(ra) # 80003c1a <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800055bc:	4601                	li	a2,0
    800055be:	fb040593          	addi	a1,s0,-80
    800055c2:	8526                	mv	a0,s1
    800055c4:	fffff097          	auipc	ra,0xfffff
    800055c8:	b3a080e7          	jalr	-1222(ra) # 800040fe <dirlookup>
    800055cc:	8aaa                	mv	s5,a0
    800055ce:	c931                	beqz	a0,80005622 <create+0x9a>
    iunlockput(dp);
    800055d0:	8526                	mv	a0,s1
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	8aa080e7          	jalr	-1878(ra) # 80003e7c <iunlockput>
    ilock(ip);
    800055da:	8556                	mv	a0,s5
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	63e080e7          	jalr	1598(ra) # 80003c1a <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800055e4:	000b059b          	sext.w	a1,s6
    800055e8:	4789                	li	a5,2
    800055ea:	02f59563          	bne	a1,a5,80005614 <create+0x8c>
    800055ee:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdcda4>
    800055f2:	37f9                	addiw	a5,a5,-2
    800055f4:	17c2                	slli	a5,a5,0x30
    800055f6:	93c1                	srli	a5,a5,0x30
    800055f8:	4705                	li	a4,1
    800055fa:	00f76d63          	bltu	a4,a5,80005614 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800055fe:	8556                	mv	a0,s5
    80005600:	60a6                	ld	ra,72(sp)
    80005602:	6406                	ld	s0,64(sp)
    80005604:	74e2                	ld	s1,56(sp)
    80005606:	7942                	ld	s2,48(sp)
    80005608:	79a2                	ld	s3,40(sp)
    8000560a:	7a02                	ld	s4,32(sp)
    8000560c:	6ae2                	ld	s5,24(sp)
    8000560e:	6b42                	ld	s6,16(sp)
    80005610:	6161                	addi	sp,sp,80
    80005612:	8082                	ret
    iunlockput(ip);
    80005614:	8556                	mv	a0,s5
    80005616:	fffff097          	auipc	ra,0xfffff
    8000561a:	866080e7          	jalr	-1946(ra) # 80003e7c <iunlockput>
    return 0;
    8000561e:	4a81                	li	s5,0
    80005620:	bff9                	j	800055fe <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005622:	85da                	mv	a1,s6
    80005624:	4088                	lw	a0,0(s1)
    80005626:	ffffe097          	auipc	ra,0xffffe
    8000562a:	456080e7          	jalr	1110(ra) # 80003a7c <ialloc>
    8000562e:	8a2a                	mv	s4,a0
    80005630:	c539                	beqz	a0,8000567e <create+0xf6>
  ilock(ip);
    80005632:	ffffe097          	auipc	ra,0xffffe
    80005636:	5e8080e7          	jalr	1512(ra) # 80003c1a <ilock>
  ip->major = major;
    8000563a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000563e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005642:	4905                	li	s2,1
    80005644:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005648:	8552                	mv	a0,s4
    8000564a:	ffffe097          	auipc	ra,0xffffe
    8000564e:	504080e7          	jalr	1284(ra) # 80003b4e <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005652:	000b059b          	sext.w	a1,s6
    80005656:	03258b63          	beq	a1,s2,8000568c <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    8000565a:	004a2603          	lw	a2,4(s4)
    8000565e:	fb040593          	addi	a1,s0,-80
    80005662:	8526                	mv	a0,s1
    80005664:	fffff097          	auipc	ra,0xfffff
    80005668:	cb0080e7          	jalr	-848(ra) # 80004314 <dirlink>
    8000566c:	06054f63          	bltz	a0,800056ea <create+0x162>
  iunlockput(dp);
    80005670:	8526                	mv	a0,s1
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	80a080e7          	jalr	-2038(ra) # 80003e7c <iunlockput>
  return ip;
    8000567a:	8ad2                	mv	s5,s4
    8000567c:	b749                	j	800055fe <create+0x76>
    iunlockput(dp);
    8000567e:	8526                	mv	a0,s1
    80005680:	ffffe097          	auipc	ra,0xffffe
    80005684:	7fc080e7          	jalr	2044(ra) # 80003e7c <iunlockput>
    return 0;
    80005688:	8ad2                	mv	s5,s4
    8000568a:	bf95                	j	800055fe <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000568c:	004a2603          	lw	a2,4(s4)
    80005690:	00003597          	auipc	a1,0x3
    80005694:	14858593          	addi	a1,a1,328 # 800087d8 <syscalls+0x2b8>
    80005698:	8552                	mv	a0,s4
    8000569a:	fffff097          	auipc	ra,0xfffff
    8000569e:	c7a080e7          	jalr	-902(ra) # 80004314 <dirlink>
    800056a2:	04054463          	bltz	a0,800056ea <create+0x162>
    800056a6:	40d0                	lw	a2,4(s1)
    800056a8:	00003597          	auipc	a1,0x3
    800056ac:	13858593          	addi	a1,a1,312 # 800087e0 <syscalls+0x2c0>
    800056b0:	8552                	mv	a0,s4
    800056b2:	fffff097          	auipc	ra,0xfffff
    800056b6:	c62080e7          	jalr	-926(ra) # 80004314 <dirlink>
    800056ba:	02054863          	bltz	a0,800056ea <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800056be:	004a2603          	lw	a2,4(s4)
    800056c2:	fb040593          	addi	a1,s0,-80
    800056c6:	8526                	mv	a0,s1
    800056c8:	fffff097          	auipc	ra,0xfffff
    800056cc:	c4c080e7          	jalr	-948(ra) # 80004314 <dirlink>
    800056d0:	00054d63          	bltz	a0,800056ea <create+0x162>
    dp->nlink++;  // for ".."
    800056d4:	04a4d783          	lhu	a5,74(s1)
    800056d8:	2785                	addiw	a5,a5,1
    800056da:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056de:	8526                	mv	a0,s1
    800056e0:	ffffe097          	auipc	ra,0xffffe
    800056e4:	46e080e7          	jalr	1134(ra) # 80003b4e <iupdate>
    800056e8:	b761                	j	80005670 <create+0xe8>
  ip->nlink = 0;
    800056ea:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800056ee:	8552                	mv	a0,s4
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	45e080e7          	jalr	1118(ra) # 80003b4e <iupdate>
  iunlockput(ip);
    800056f8:	8552                	mv	a0,s4
    800056fa:	ffffe097          	auipc	ra,0xffffe
    800056fe:	782080e7          	jalr	1922(ra) # 80003e7c <iunlockput>
  iunlockput(dp);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	778080e7          	jalr	1912(ra) # 80003e7c <iunlockput>
  return 0;
    8000570c:	bdcd                	j	800055fe <create+0x76>
    return 0;
    8000570e:	8aaa                	mv	s5,a0
    80005710:	b5fd                	j	800055fe <create+0x76>

0000000080005712 <sys_dup>:
{
    80005712:	7179                	addi	sp,sp,-48
    80005714:	f406                	sd	ra,40(sp)
    80005716:	f022                	sd	s0,32(sp)
    80005718:	ec26                	sd	s1,24(sp)
    8000571a:	e84a                	sd	s2,16(sp)
    8000571c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000571e:	fd840613          	addi	a2,s0,-40
    80005722:	4581                	li	a1,0
    80005724:	4501                	li	a0,0
    80005726:	00000097          	auipc	ra,0x0
    8000572a:	dc0080e7          	jalr	-576(ra) # 800054e6 <argfd>
    return -1;
    8000572e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005730:	02054363          	bltz	a0,80005756 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80005734:	fd843903          	ld	s2,-40(s0)
    80005738:	854a                	mv	a0,s2
    8000573a:	00000097          	auipc	ra,0x0
    8000573e:	e0c080e7          	jalr	-500(ra) # 80005546 <fdalloc>
    80005742:	84aa                	mv	s1,a0
    return -1;
    80005744:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005746:	00054863          	bltz	a0,80005756 <sys_dup+0x44>
  filedup(f);
    8000574a:	854a                	mv	a0,s2
    8000574c:	fffff097          	auipc	ra,0xfffff
    80005750:	310080e7          	jalr	784(ra) # 80004a5c <filedup>
  return fd;
    80005754:	87a6                	mv	a5,s1
}
    80005756:	853e                	mv	a0,a5
    80005758:	70a2                	ld	ra,40(sp)
    8000575a:	7402                	ld	s0,32(sp)
    8000575c:	64e2                	ld	s1,24(sp)
    8000575e:	6942                	ld	s2,16(sp)
    80005760:	6145                	addi	sp,sp,48
    80005762:	8082                	ret

0000000080005764 <sys_read>:
{
    80005764:	7179                	addi	sp,sp,-48
    80005766:	f406                	sd	ra,40(sp)
    80005768:	f022                	sd	s0,32(sp)
    8000576a:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000576c:	fd840593          	addi	a1,s0,-40
    80005770:	4505                	li	a0,1
    80005772:	ffffe097          	auipc	ra,0xffffe
    80005776:	8ce080e7          	jalr	-1842(ra) # 80003040 <argaddr>
  argint(2, &n);
    8000577a:	fe440593          	addi	a1,s0,-28
    8000577e:	4509                	li	a0,2
    80005780:	ffffe097          	auipc	ra,0xffffe
    80005784:	8a0080e7          	jalr	-1888(ra) # 80003020 <argint>
  if(argfd(0, 0, &f) < 0)
    80005788:	fe840613          	addi	a2,s0,-24
    8000578c:	4581                	li	a1,0
    8000578e:	4501                	li	a0,0
    80005790:	00000097          	auipc	ra,0x0
    80005794:	d56080e7          	jalr	-682(ra) # 800054e6 <argfd>
    80005798:	87aa                	mv	a5,a0
    return -1;
    8000579a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000579c:	0007cc63          	bltz	a5,800057b4 <sys_read+0x50>
  return fileread(f, p, n);
    800057a0:	fe442603          	lw	a2,-28(s0)
    800057a4:	fd843583          	ld	a1,-40(s0)
    800057a8:	fe843503          	ld	a0,-24(s0)
    800057ac:	fffff097          	auipc	ra,0xfffff
    800057b0:	43c080e7          	jalr	1084(ra) # 80004be8 <fileread>
}
    800057b4:	70a2                	ld	ra,40(sp)
    800057b6:	7402                	ld	s0,32(sp)
    800057b8:	6145                	addi	sp,sp,48
    800057ba:	8082                	ret

00000000800057bc <sys_write>:
{
    800057bc:	7179                	addi	sp,sp,-48
    800057be:	f406                	sd	ra,40(sp)
    800057c0:	f022                	sd	s0,32(sp)
    800057c2:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800057c4:	fd840593          	addi	a1,s0,-40
    800057c8:	4505                	li	a0,1
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	876080e7          	jalr	-1930(ra) # 80003040 <argaddr>
  argint(2, &n);
    800057d2:	fe440593          	addi	a1,s0,-28
    800057d6:	4509                	li	a0,2
    800057d8:	ffffe097          	auipc	ra,0xffffe
    800057dc:	848080e7          	jalr	-1976(ra) # 80003020 <argint>
  if(argfd(0, 0, &f) < 0)
    800057e0:	fe840613          	addi	a2,s0,-24
    800057e4:	4581                	li	a1,0
    800057e6:	4501                	li	a0,0
    800057e8:	00000097          	auipc	ra,0x0
    800057ec:	cfe080e7          	jalr	-770(ra) # 800054e6 <argfd>
    800057f0:	87aa                	mv	a5,a0
    return -1;
    800057f2:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800057f4:	0007cc63          	bltz	a5,8000580c <sys_write+0x50>
  return filewrite(f, p, n);
    800057f8:	fe442603          	lw	a2,-28(s0)
    800057fc:	fd843583          	ld	a1,-40(s0)
    80005800:	fe843503          	ld	a0,-24(s0)
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	4a6080e7          	jalr	1190(ra) # 80004caa <filewrite>
}
    8000580c:	70a2                	ld	ra,40(sp)
    8000580e:	7402                	ld	s0,32(sp)
    80005810:	6145                	addi	sp,sp,48
    80005812:	8082                	ret

0000000080005814 <sys_close>:
{
    80005814:	1101                	addi	sp,sp,-32
    80005816:	ec06                	sd	ra,24(sp)
    80005818:	e822                	sd	s0,16(sp)
    8000581a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000581c:	fe040613          	addi	a2,s0,-32
    80005820:	fec40593          	addi	a1,s0,-20
    80005824:	4501                	li	a0,0
    80005826:	00000097          	auipc	ra,0x0
    8000582a:	cc0080e7          	jalr	-832(ra) # 800054e6 <argfd>
    return -1;
    8000582e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005830:	02054463          	bltz	a0,80005858 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005834:	ffffc097          	auipc	ra,0xffffc
    80005838:	256080e7          	jalr	598(ra) # 80001a8a <myproc>
    8000583c:	fec42783          	lw	a5,-20(s0)
    80005840:	07f1                	addi	a5,a5,28
    80005842:	078e                	slli	a5,a5,0x3
    80005844:	953e                	add	a0,a0,a5
    80005846:	00053023          	sd	zero,0(a0)
  fileclose(f);
    8000584a:	fe043503          	ld	a0,-32(s0)
    8000584e:	fffff097          	auipc	ra,0xfffff
    80005852:	260080e7          	jalr	608(ra) # 80004aae <fileclose>
  return 0;
    80005856:	4781                	li	a5,0
}
    80005858:	853e                	mv	a0,a5
    8000585a:	60e2                	ld	ra,24(sp)
    8000585c:	6442                	ld	s0,16(sp)
    8000585e:	6105                	addi	sp,sp,32
    80005860:	8082                	ret

0000000080005862 <sys_fstat>:
{
    80005862:	1101                	addi	sp,sp,-32
    80005864:	ec06                	sd	ra,24(sp)
    80005866:	e822                	sd	s0,16(sp)
    80005868:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    8000586a:	fe040593          	addi	a1,s0,-32
    8000586e:	4505                	li	a0,1
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	7d0080e7          	jalr	2000(ra) # 80003040 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005878:	fe840613          	addi	a2,s0,-24
    8000587c:	4581                	li	a1,0
    8000587e:	4501                	li	a0,0
    80005880:	00000097          	auipc	ra,0x0
    80005884:	c66080e7          	jalr	-922(ra) # 800054e6 <argfd>
    80005888:	87aa                	mv	a5,a0
    return -1;
    8000588a:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000588c:	0007ca63          	bltz	a5,800058a0 <sys_fstat+0x3e>
  return filestat(f, st);
    80005890:	fe043583          	ld	a1,-32(s0)
    80005894:	fe843503          	ld	a0,-24(s0)
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	2de080e7          	jalr	734(ra) # 80004b76 <filestat>
}
    800058a0:	60e2                	ld	ra,24(sp)
    800058a2:	6442                	ld	s0,16(sp)
    800058a4:	6105                	addi	sp,sp,32
    800058a6:	8082                	ret

00000000800058a8 <sys_link>:
{
    800058a8:	7169                	addi	sp,sp,-304
    800058aa:	f606                	sd	ra,296(sp)
    800058ac:	f222                	sd	s0,288(sp)
    800058ae:	ee26                	sd	s1,280(sp)
    800058b0:	ea4a                	sd	s2,272(sp)
    800058b2:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058b4:	08000613          	li	a2,128
    800058b8:	ed040593          	addi	a1,s0,-304
    800058bc:	4501                	li	a0,0
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	7a2080e7          	jalr	1954(ra) # 80003060 <argstr>
    return -1;
    800058c6:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058c8:	10054e63          	bltz	a0,800059e4 <sys_link+0x13c>
    800058cc:	08000613          	li	a2,128
    800058d0:	f5040593          	addi	a1,s0,-176
    800058d4:	4505                	li	a0,1
    800058d6:	ffffd097          	auipc	ra,0xffffd
    800058da:	78a080e7          	jalr	1930(ra) # 80003060 <argstr>
    return -1;
    800058de:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800058e0:	10054263          	bltz	a0,800059e4 <sys_link+0x13c>
  begin_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	d02080e7          	jalr	-766(ra) # 800045e6 <begin_op>
  if((ip = namei(old)) == 0){
    800058ec:	ed040513          	addi	a0,s0,-304
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	ad6080e7          	jalr	-1322(ra) # 800043c6 <namei>
    800058f8:	84aa                	mv	s1,a0
    800058fa:	c551                	beqz	a0,80005986 <sys_link+0xde>
  ilock(ip);
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	31e080e7          	jalr	798(ra) # 80003c1a <ilock>
  if(ip->type == T_DIR){
    80005904:	04449703          	lh	a4,68(s1)
    80005908:	4785                	li	a5,1
    8000590a:	08f70463          	beq	a4,a5,80005992 <sys_link+0xea>
  ip->nlink++;
    8000590e:	04a4d783          	lhu	a5,74(s1)
    80005912:	2785                	addiw	a5,a5,1
    80005914:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005918:	8526                	mv	a0,s1
    8000591a:	ffffe097          	auipc	ra,0xffffe
    8000591e:	234080e7          	jalr	564(ra) # 80003b4e <iupdate>
  iunlock(ip);
    80005922:	8526                	mv	a0,s1
    80005924:	ffffe097          	auipc	ra,0xffffe
    80005928:	3b8080e7          	jalr	952(ra) # 80003cdc <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000592c:	fd040593          	addi	a1,s0,-48
    80005930:	f5040513          	addi	a0,s0,-176
    80005934:	fffff097          	auipc	ra,0xfffff
    80005938:	ab0080e7          	jalr	-1360(ra) # 800043e4 <nameiparent>
    8000593c:	892a                	mv	s2,a0
    8000593e:	c935                	beqz	a0,800059b2 <sys_link+0x10a>
  ilock(dp);
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	2da080e7          	jalr	730(ra) # 80003c1a <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005948:	00092703          	lw	a4,0(s2)
    8000594c:	409c                	lw	a5,0(s1)
    8000594e:	04f71d63          	bne	a4,a5,800059a8 <sys_link+0x100>
    80005952:	40d0                	lw	a2,4(s1)
    80005954:	fd040593          	addi	a1,s0,-48
    80005958:	854a                	mv	a0,s2
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	9ba080e7          	jalr	-1606(ra) # 80004314 <dirlink>
    80005962:	04054363          	bltz	a0,800059a8 <sys_link+0x100>
  iunlockput(dp);
    80005966:	854a                	mv	a0,s2
    80005968:	ffffe097          	auipc	ra,0xffffe
    8000596c:	514080e7          	jalr	1300(ra) # 80003e7c <iunlockput>
  iput(ip);
    80005970:	8526                	mv	a0,s1
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	462080e7          	jalr	1122(ra) # 80003dd4 <iput>
  end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	cea080e7          	jalr	-790(ra) # 80004664 <end_op>
  return 0;
    80005982:	4781                	li	a5,0
    80005984:	a085                	j	800059e4 <sys_link+0x13c>
    end_op();
    80005986:	fffff097          	auipc	ra,0xfffff
    8000598a:	cde080e7          	jalr	-802(ra) # 80004664 <end_op>
    return -1;
    8000598e:	57fd                	li	a5,-1
    80005990:	a891                	j	800059e4 <sys_link+0x13c>
    iunlockput(ip);
    80005992:	8526                	mv	a0,s1
    80005994:	ffffe097          	auipc	ra,0xffffe
    80005998:	4e8080e7          	jalr	1256(ra) # 80003e7c <iunlockput>
    end_op();
    8000599c:	fffff097          	auipc	ra,0xfffff
    800059a0:	cc8080e7          	jalr	-824(ra) # 80004664 <end_op>
    return -1;
    800059a4:	57fd                	li	a5,-1
    800059a6:	a83d                	j	800059e4 <sys_link+0x13c>
    iunlockput(dp);
    800059a8:	854a                	mv	a0,s2
    800059aa:	ffffe097          	auipc	ra,0xffffe
    800059ae:	4d2080e7          	jalr	1234(ra) # 80003e7c <iunlockput>
  ilock(ip);
    800059b2:	8526                	mv	a0,s1
    800059b4:	ffffe097          	auipc	ra,0xffffe
    800059b8:	266080e7          	jalr	614(ra) # 80003c1a <ilock>
  ip->nlink--;
    800059bc:	04a4d783          	lhu	a5,74(s1)
    800059c0:	37fd                	addiw	a5,a5,-1
    800059c2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059c6:	8526                	mv	a0,s1
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	186080e7          	jalr	390(ra) # 80003b4e <iupdate>
  iunlockput(ip);
    800059d0:	8526                	mv	a0,s1
    800059d2:	ffffe097          	auipc	ra,0xffffe
    800059d6:	4aa080e7          	jalr	1194(ra) # 80003e7c <iunlockput>
  end_op();
    800059da:	fffff097          	auipc	ra,0xfffff
    800059de:	c8a080e7          	jalr	-886(ra) # 80004664 <end_op>
  return -1;
    800059e2:	57fd                	li	a5,-1
}
    800059e4:	853e                	mv	a0,a5
    800059e6:	70b2                	ld	ra,296(sp)
    800059e8:	7412                	ld	s0,288(sp)
    800059ea:	64f2                	ld	s1,280(sp)
    800059ec:	6952                	ld	s2,272(sp)
    800059ee:	6155                	addi	sp,sp,304
    800059f0:	8082                	ret

00000000800059f2 <sys_unlink>:
{
    800059f2:	7151                	addi	sp,sp,-240
    800059f4:	f586                	sd	ra,232(sp)
    800059f6:	f1a2                	sd	s0,224(sp)
    800059f8:	eda6                	sd	s1,216(sp)
    800059fa:	e9ca                	sd	s2,208(sp)
    800059fc:	e5ce                	sd	s3,200(sp)
    800059fe:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005a00:	08000613          	li	a2,128
    80005a04:	f3040593          	addi	a1,s0,-208
    80005a08:	4501                	li	a0,0
    80005a0a:	ffffd097          	auipc	ra,0xffffd
    80005a0e:	656080e7          	jalr	1622(ra) # 80003060 <argstr>
    80005a12:	18054163          	bltz	a0,80005b94 <sys_unlink+0x1a2>
  begin_op();
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	bd0080e7          	jalr	-1072(ra) # 800045e6 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005a1e:	fb040593          	addi	a1,s0,-80
    80005a22:	f3040513          	addi	a0,s0,-208
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	9be080e7          	jalr	-1602(ra) # 800043e4 <nameiparent>
    80005a2e:	84aa                	mv	s1,a0
    80005a30:	c979                	beqz	a0,80005b06 <sys_unlink+0x114>
  ilock(dp);
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	1e8080e7          	jalr	488(ra) # 80003c1a <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005a3a:	00003597          	auipc	a1,0x3
    80005a3e:	d9e58593          	addi	a1,a1,-610 # 800087d8 <syscalls+0x2b8>
    80005a42:	fb040513          	addi	a0,s0,-80
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	69e080e7          	jalr	1694(ra) # 800040e4 <namecmp>
    80005a4e:	14050a63          	beqz	a0,80005ba2 <sys_unlink+0x1b0>
    80005a52:	00003597          	auipc	a1,0x3
    80005a56:	d8e58593          	addi	a1,a1,-626 # 800087e0 <syscalls+0x2c0>
    80005a5a:	fb040513          	addi	a0,s0,-80
    80005a5e:	ffffe097          	auipc	ra,0xffffe
    80005a62:	686080e7          	jalr	1670(ra) # 800040e4 <namecmp>
    80005a66:	12050e63          	beqz	a0,80005ba2 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a6a:	f2c40613          	addi	a2,s0,-212
    80005a6e:	fb040593          	addi	a1,s0,-80
    80005a72:	8526                	mv	a0,s1
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	68a080e7          	jalr	1674(ra) # 800040fe <dirlookup>
    80005a7c:	892a                	mv	s2,a0
    80005a7e:	12050263          	beqz	a0,80005ba2 <sys_unlink+0x1b0>
  ilock(ip);
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	198080e7          	jalr	408(ra) # 80003c1a <ilock>
  if(ip->nlink < 1)
    80005a8a:	04a91783          	lh	a5,74(s2)
    80005a8e:	08f05263          	blez	a5,80005b12 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a92:	04491703          	lh	a4,68(s2)
    80005a96:	4785                	li	a5,1
    80005a98:	08f70563          	beq	a4,a5,80005b22 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a9c:	4641                	li	a2,16
    80005a9e:	4581                	li	a1,0
    80005aa0:	fc040513          	addi	a0,s0,-64
    80005aa4:	ffffb097          	auipc	ra,0xffffb
    80005aa8:	22e080e7          	jalr	558(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005aac:	4741                	li	a4,16
    80005aae:	f2c42683          	lw	a3,-212(s0)
    80005ab2:	fc040613          	addi	a2,s0,-64
    80005ab6:	4581                	li	a1,0
    80005ab8:	8526                	mv	a0,s1
    80005aba:	ffffe097          	auipc	ra,0xffffe
    80005abe:	50c080e7          	jalr	1292(ra) # 80003fc6 <writei>
    80005ac2:	47c1                	li	a5,16
    80005ac4:	0af51563          	bne	a0,a5,80005b6e <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005ac8:	04491703          	lh	a4,68(s2)
    80005acc:	4785                	li	a5,1
    80005ace:	0af70863          	beq	a4,a5,80005b7e <sys_unlink+0x18c>
  iunlockput(dp);
    80005ad2:	8526                	mv	a0,s1
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	3a8080e7          	jalr	936(ra) # 80003e7c <iunlockput>
  ip->nlink--;
    80005adc:	04a95783          	lhu	a5,74(s2)
    80005ae0:	37fd                	addiw	a5,a5,-1
    80005ae2:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005ae6:	854a                	mv	a0,s2
    80005ae8:	ffffe097          	auipc	ra,0xffffe
    80005aec:	066080e7          	jalr	102(ra) # 80003b4e <iupdate>
  iunlockput(ip);
    80005af0:	854a                	mv	a0,s2
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	38a080e7          	jalr	906(ra) # 80003e7c <iunlockput>
  end_op();
    80005afa:	fffff097          	auipc	ra,0xfffff
    80005afe:	b6a080e7          	jalr	-1174(ra) # 80004664 <end_op>
  return 0;
    80005b02:	4501                	li	a0,0
    80005b04:	a84d                	j	80005bb6 <sys_unlink+0x1c4>
    end_op();
    80005b06:	fffff097          	auipc	ra,0xfffff
    80005b0a:	b5e080e7          	jalr	-1186(ra) # 80004664 <end_op>
    return -1;
    80005b0e:	557d                	li	a0,-1
    80005b10:	a05d                	j	80005bb6 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005b12:	00003517          	auipc	a0,0x3
    80005b16:	cd650513          	addi	a0,a0,-810 # 800087e8 <syscalls+0x2c8>
    80005b1a:	ffffb097          	auipc	ra,0xffffb
    80005b1e:	a26080e7          	jalr	-1498(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b22:	04c92703          	lw	a4,76(s2)
    80005b26:	02000793          	li	a5,32
    80005b2a:	f6e7f9e3          	bgeu	a5,a4,80005a9c <sys_unlink+0xaa>
    80005b2e:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005b32:	4741                	li	a4,16
    80005b34:	86ce                	mv	a3,s3
    80005b36:	f1840613          	addi	a2,s0,-232
    80005b3a:	4581                	li	a1,0
    80005b3c:	854a                	mv	a0,s2
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	390080e7          	jalr	912(ra) # 80003ece <readi>
    80005b46:	47c1                	li	a5,16
    80005b48:	00f51b63          	bne	a0,a5,80005b5e <sys_unlink+0x16c>
    if(de.inum != 0)
    80005b4c:	f1845783          	lhu	a5,-232(s0)
    80005b50:	e7a1                	bnez	a5,80005b98 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005b52:	29c1                	addiw	s3,s3,16
    80005b54:	04c92783          	lw	a5,76(s2)
    80005b58:	fcf9ede3          	bltu	s3,a5,80005b32 <sys_unlink+0x140>
    80005b5c:	b781                	j	80005a9c <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005b5e:	00003517          	auipc	a0,0x3
    80005b62:	ca250513          	addi	a0,a0,-862 # 80008800 <syscalls+0x2e0>
    80005b66:	ffffb097          	auipc	ra,0xffffb
    80005b6a:	9da080e7          	jalr	-1574(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005b6e:	00003517          	auipc	a0,0x3
    80005b72:	caa50513          	addi	a0,a0,-854 # 80008818 <syscalls+0x2f8>
    80005b76:	ffffb097          	auipc	ra,0xffffb
    80005b7a:	9ca080e7          	jalr	-1590(ra) # 80000540 <panic>
    dp->nlink--;
    80005b7e:	04a4d783          	lhu	a5,74(s1)
    80005b82:	37fd                	addiw	a5,a5,-1
    80005b84:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005b88:	8526                	mv	a0,s1
    80005b8a:	ffffe097          	auipc	ra,0xffffe
    80005b8e:	fc4080e7          	jalr	-60(ra) # 80003b4e <iupdate>
    80005b92:	b781                	j	80005ad2 <sys_unlink+0xe0>
    return -1;
    80005b94:	557d                	li	a0,-1
    80005b96:	a005                	j	80005bb6 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b98:	854a                	mv	a0,s2
    80005b9a:	ffffe097          	auipc	ra,0xffffe
    80005b9e:	2e2080e7          	jalr	738(ra) # 80003e7c <iunlockput>
  iunlockput(dp);
    80005ba2:	8526                	mv	a0,s1
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	2d8080e7          	jalr	728(ra) # 80003e7c <iunlockput>
  end_op();
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	ab8080e7          	jalr	-1352(ra) # 80004664 <end_op>
  return -1;
    80005bb4:	557d                	li	a0,-1
}
    80005bb6:	70ae                	ld	ra,232(sp)
    80005bb8:	740e                	ld	s0,224(sp)
    80005bba:	64ee                	ld	s1,216(sp)
    80005bbc:	694e                	ld	s2,208(sp)
    80005bbe:	69ae                	ld	s3,200(sp)
    80005bc0:	616d                	addi	sp,sp,240
    80005bc2:	8082                	ret

0000000080005bc4 <sys_open>:

uint64
sys_open(void)
{
    80005bc4:	7131                	addi	sp,sp,-192
    80005bc6:	fd06                	sd	ra,184(sp)
    80005bc8:	f922                	sd	s0,176(sp)
    80005bca:	f526                	sd	s1,168(sp)
    80005bcc:	f14a                	sd	s2,160(sp)
    80005bce:	ed4e                	sd	s3,152(sp)
    80005bd0:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005bd2:	f4c40593          	addi	a1,s0,-180
    80005bd6:	4505                	li	a0,1
    80005bd8:	ffffd097          	auipc	ra,0xffffd
    80005bdc:	448080e7          	jalr	1096(ra) # 80003020 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005be0:	08000613          	li	a2,128
    80005be4:	f5040593          	addi	a1,s0,-176
    80005be8:	4501                	li	a0,0
    80005bea:	ffffd097          	auipc	ra,0xffffd
    80005bee:	476080e7          	jalr	1142(ra) # 80003060 <argstr>
    80005bf2:	87aa                	mv	a5,a0
    return -1;
    80005bf4:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005bf6:	0a07c963          	bltz	a5,80005ca8 <sys_open+0xe4>

  begin_op();
    80005bfa:	fffff097          	auipc	ra,0xfffff
    80005bfe:	9ec080e7          	jalr	-1556(ra) # 800045e6 <begin_op>

  if(omode & O_CREATE){
    80005c02:	f4c42783          	lw	a5,-180(s0)
    80005c06:	2007f793          	andi	a5,a5,512
    80005c0a:	cfc5                	beqz	a5,80005cc2 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005c0c:	4681                	li	a3,0
    80005c0e:	4601                	li	a2,0
    80005c10:	4589                	li	a1,2
    80005c12:	f5040513          	addi	a0,s0,-176
    80005c16:	00000097          	auipc	ra,0x0
    80005c1a:	972080e7          	jalr	-1678(ra) # 80005588 <create>
    80005c1e:	84aa                	mv	s1,a0
    if(ip == 0){
    80005c20:	c959                	beqz	a0,80005cb6 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005c22:	04449703          	lh	a4,68(s1)
    80005c26:	478d                	li	a5,3
    80005c28:	00f71763          	bne	a4,a5,80005c36 <sys_open+0x72>
    80005c2c:	0464d703          	lhu	a4,70(s1)
    80005c30:	47a5                	li	a5,9
    80005c32:	0ce7ed63          	bltu	a5,a4,80005d0c <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005c36:	fffff097          	auipc	ra,0xfffff
    80005c3a:	dbc080e7          	jalr	-580(ra) # 800049f2 <filealloc>
    80005c3e:	89aa                	mv	s3,a0
    80005c40:	10050363          	beqz	a0,80005d46 <sys_open+0x182>
    80005c44:	00000097          	auipc	ra,0x0
    80005c48:	902080e7          	jalr	-1790(ra) # 80005546 <fdalloc>
    80005c4c:	892a                	mv	s2,a0
    80005c4e:	0e054763          	bltz	a0,80005d3c <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005c52:	04449703          	lh	a4,68(s1)
    80005c56:	478d                	li	a5,3
    80005c58:	0cf70563          	beq	a4,a5,80005d22 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005c5c:	4789                	li	a5,2
    80005c5e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005c62:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c66:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c6a:	f4c42783          	lw	a5,-180(s0)
    80005c6e:	0017c713          	xori	a4,a5,1
    80005c72:	8b05                	andi	a4,a4,1
    80005c74:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c78:	0037f713          	andi	a4,a5,3
    80005c7c:	00e03733          	snez	a4,a4
    80005c80:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c84:	4007f793          	andi	a5,a5,1024
    80005c88:	c791                	beqz	a5,80005c94 <sys_open+0xd0>
    80005c8a:	04449703          	lh	a4,68(s1)
    80005c8e:	4789                	li	a5,2
    80005c90:	0af70063          	beq	a4,a5,80005d30 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c94:	8526                	mv	a0,s1
    80005c96:	ffffe097          	auipc	ra,0xffffe
    80005c9a:	046080e7          	jalr	70(ra) # 80003cdc <iunlock>
  end_op();
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	9c6080e7          	jalr	-1594(ra) # 80004664 <end_op>

  return fd;
    80005ca6:	854a                	mv	a0,s2
}
    80005ca8:	70ea                	ld	ra,184(sp)
    80005caa:	744a                	ld	s0,176(sp)
    80005cac:	74aa                	ld	s1,168(sp)
    80005cae:	790a                	ld	s2,160(sp)
    80005cb0:	69ea                	ld	s3,152(sp)
    80005cb2:	6129                	addi	sp,sp,192
    80005cb4:	8082                	ret
      end_op();
    80005cb6:	fffff097          	auipc	ra,0xfffff
    80005cba:	9ae080e7          	jalr	-1618(ra) # 80004664 <end_op>
      return -1;
    80005cbe:	557d                	li	a0,-1
    80005cc0:	b7e5                	j	80005ca8 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005cc2:	f5040513          	addi	a0,s0,-176
    80005cc6:	ffffe097          	auipc	ra,0xffffe
    80005cca:	700080e7          	jalr	1792(ra) # 800043c6 <namei>
    80005cce:	84aa                	mv	s1,a0
    80005cd0:	c905                	beqz	a0,80005d00 <sys_open+0x13c>
    ilock(ip);
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	f48080e7          	jalr	-184(ra) # 80003c1a <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005cda:	04449703          	lh	a4,68(s1)
    80005cde:	4785                	li	a5,1
    80005ce0:	f4f711e3          	bne	a4,a5,80005c22 <sys_open+0x5e>
    80005ce4:	f4c42783          	lw	a5,-180(s0)
    80005ce8:	d7b9                	beqz	a5,80005c36 <sys_open+0x72>
      iunlockput(ip);
    80005cea:	8526                	mv	a0,s1
    80005cec:	ffffe097          	auipc	ra,0xffffe
    80005cf0:	190080e7          	jalr	400(ra) # 80003e7c <iunlockput>
      end_op();
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	970080e7          	jalr	-1680(ra) # 80004664 <end_op>
      return -1;
    80005cfc:	557d                	li	a0,-1
    80005cfe:	b76d                	j	80005ca8 <sys_open+0xe4>
      end_op();
    80005d00:	fffff097          	auipc	ra,0xfffff
    80005d04:	964080e7          	jalr	-1692(ra) # 80004664 <end_op>
      return -1;
    80005d08:	557d                	li	a0,-1
    80005d0a:	bf79                	j	80005ca8 <sys_open+0xe4>
    iunlockput(ip);
    80005d0c:	8526                	mv	a0,s1
    80005d0e:	ffffe097          	auipc	ra,0xffffe
    80005d12:	16e080e7          	jalr	366(ra) # 80003e7c <iunlockput>
    end_op();
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	94e080e7          	jalr	-1714(ra) # 80004664 <end_op>
    return -1;
    80005d1e:	557d                	li	a0,-1
    80005d20:	b761                	j	80005ca8 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005d22:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005d26:	04649783          	lh	a5,70(s1)
    80005d2a:	02f99223          	sh	a5,36(s3)
    80005d2e:	bf25                	j	80005c66 <sys_open+0xa2>
    itrunc(ip);
    80005d30:	8526                	mv	a0,s1
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	ff6080e7          	jalr	-10(ra) # 80003d28 <itrunc>
    80005d3a:	bfa9                	j	80005c94 <sys_open+0xd0>
      fileclose(f);
    80005d3c:	854e                	mv	a0,s3
    80005d3e:	fffff097          	auipc	ra,0xfffff
    80005d42:	d70080e7          	jalr	-656(ra) # 80004aae <fileclose>
    iunlockput(ip);
    80005d46:	8526                	mv	a0,s1
    80005d48:	ffffe097          	auipc	ra,0xffffe
    80005d4c:	134080e7          	jalr	308(ra) # 80003e7c <iunlockput>
    end_op();
    80005d50:	fffff097          	auipc	ra,0xfffff
    80005d54:	914080e7          	jalr	-1772(ra) # 80004664 <end_op>
    return -1;
    80005d58:	557d                	li	a0,-1
    80005d5a:	b7b9                	j	80005ca8 <sys_open+0xe4>

0000000080005d5c <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005d5c:	7175                	addi	sp,sp,-144
    80005d5e:	e506                	sd	ra,136(sp)
    80005d60:	e122                	sd	s0,128(sp)
    80005d62:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005d64:	fffff097          	auipc	ra,0xfffff
    80005d68:	882080e7          	jalr	-1918(ra) # 800045e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d6c:	08000613          	li	a2,128
    80005d70:	f7040593          	addi	a1,s0,-144
    80005d74:	4501                	li	a0,0
    80005d76:	ffffd097          	auipc	ra,0xffffd
    80005d7a:	2ea080e7          	jalr	746(ra) # 80003060 <argstr>
    80005d7e:	02054963          	bltz	a0,80005db0 <sys_mkdir+0x54>
    80005d82:	4681                	li	a3,0
    80005d84:	4601                	li	a2,0
    80005d86:	4585                	li	a1,1
    80005d88:	f7040513          	addi	a0,s0,-144
    80005d8c:	fffff097          	auipc	ra,0xfffff
    80005d90:	7fc080e7          	jalr	2044(ra) # 80005588 <create>
    80005d94:	cd11                	beqz	a0,80005db0 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d96:	ffffe097          	auipc	ra,0xffffe
    80005d9a:	0e6080e7          	jalr	230(ra) # 80003e7c <iunlockput>
  end_op();
    80005d9e:	fffff097          	auipc	ra,0xfffff
    80005da2:	8c6080e7          	jalr	-1850(ra) # 80004664 <end_op>
  return 0;
    80005da6:	4501                	li	a0,0
}
    80005da8:	60aa                	ld	ra,136(sp)
    80005daa:	640a                	ld	s0,128(sp)
    80005dac:	6149                	addi	sp,sp,144
    80005dae:	8082                	ret
    end_op();
    80005db0:	fffff097          	auipc	ra,0xfffff
    80005db4:	8b4080e7          	jalr	-1868(ra) # 80004664 <end_op>
    return -1;
    80005db8:	557d                	li	a0,-1
    80005dba:	b7fd                	j	80005da8 <sys_mkdir+0x4c>

0000000080005dbc <sys_mknod>:

uint64
sys_mknod(void)
{
    80005dbc:	7135                	addi	sp,sp,-160
    80005dbe:	ed06                	sd	ra,152(sp)
    80005dc0:	e922                	sd	s0,144(sp)
    80005dc2:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005dc4:	fffff097          	auipc	ra,0xfffff
    80005dc8:	822080e7          	jalr	-2014(ra) # 800045e6 <begin_op>
  argint(1, &major);
    80005dcc:	f6c40593          	addi	a1,s0,-148
    80005dd0:	4505                	li	a0,1
    80005dd2:	ffffd097          	auipc	ra,0xffffd
    80005dd6:	24e080e7          	jalr	590(ra) # 80003020 <argint>
  argint(2, &minor);
    80005dda:	f6840593          	addi	a1,s0,-152
    80005dde:	4509                	li	a0,2
    80005de0:	ffffd097          	auipc	ra,0xffffd
    80005de4:	240080e7          	jalr	576(ra) # 80003020 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005de8:	08000613          	li	a2,128
    80005dec:	f7040593          	addi	a1,s0,-144
    80005df0:	4501                	li	a0,0
    80005df2:	ffffd097          	auipc	ra,0xffffd
    80005df6:	26e080e7          	jalr	622(ra) # 80003060 <argstr>
    80005dfa:	02054b63          	bltz	a0,80005e30 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005dfe:	f6841683          	lh	a3,-152(s0)
    80005e02:	f6c41603          	lh	a2,-148(s0)
    80005e06:	458d                	li	a1,3
    80005e08:	f7040513          	addi	a0,s0,-144
    80005e0c:	fffff097          	auipc	ra,0xfffff
    80005e10:	77c080e7          	jalr	1916(ra) # 80005588 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005e14:	cd11                	beqz	a0,80005e30 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	066080e7          	jalr	102(ra) # 80003e7c <iunlockput>
  end_op();
    80005e1e:	fffff097          	auipc	ra,0xfffff
    80005e22:	846080e7          	jalr	-1978(ra) # 80004664 <end_op>
  return 0;
    80005e26:	4501                	li	a0,0
}
    80005e28:	60ea                	ld	ra,152(sp)
    80005e2a:	644a                	ld	s0,144(sp)
    80005e2c:	610d                	addi	sp,sp,160
    80005e2e:	8082                	ret
    end_op();
    80005e30:	fffff097          	auipc	ra,0xfffff
    80005e34:	834080e7          	jalr	-1996(ra) # 80004664 <end_op>
    return -1;
    80005e38:	557d                	li	a0,-1
    80005e3a:	b7fd                	j	80005e28 <sys_mknod+0x6c>

0000000080005e3c <sys_chdir>:

uint64
sys_chdir(void)
{
    80005e3c:	7135                	addi	sp,sp,-160
    80005e3e:	ed06                	sd	ra,152(sp)
    80005e40:	e922                	sd	s0,144(sp)
    80005e42:	e526                	sd	s1,136(sp)
    80005e44:	e14a                	sd	s2,128(sp)
    80005e46:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005e48:	ffffc097          	auipc	ra,0xffffc
    80005e4c:	c42080e7          	jalr	-958(ra) # 80001a8a <myproc>
    80005e50:	892a                	mv	s2,a0
  
  begin_op();
    80005e52:	ffffe097          	auipc	ra,0xffffe
    80005e56:	794080e7          	jalr	1940(ra) # 800045e6 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005e5a:	08000613          	li	a2,128
    80005e5e:	f6040593          	addi	a1,s0,-160
    80005e62:	4501                	li	a0,0
    80005e64:	ffffd097          	auipc	ra,0xffffd
    80005e68:	1fc080e7          	jalr	508(ra) # 80003060 <argstr>
    80005e6c:	04054b63          	bltz	a0,80005ec2 <sys_chdir+0x86>
    80005e70:	f6040513          	addi	a0,s0,-160
    80005e74:	ffffe097          	auipc	ra,0xffffe
    80005e78:	552080e7          	jalr	1362(ra) # 800043c6 <namei>
    80005e7c:	84aa                	mv	s1,a0
    80005e7e:	c131                	beqz	a0,80005ec2 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e80:	ffffe097          	auipc	ra,0xffffe
    80005e84:	d9a080e7          	jalr	-614(ra) # 80003c1a <ilock>
  if(ip->type != T_DIR){
    80005e88:	04449703          	lh	a4,68(s1)
    80005e8c:	4785                	li	a5,1
    80005e8e:	04f71063          	bne	a4,a5,80005ece <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e92:	8526                	mv	a0,s1
    80005e94:	ffffe097          	auipc	ra,0xffffe
    80005e98:	e48080e7          	jalr	-440(ra) # 80003cdc <iunlock>
  iput(p->cwd);
    80005e9c:	16093503          	ld	a0,352(s2)
    80005ea0:	ffffe097          	auipc	ra,0xffffe
    80005ea4:	f34080e7          	jalr	-204(ra) # 80003dd4 <iput>
  end_op();
    80005ea8:	ffffe097          	auipc	ra,0xffffe
    80005eac:	7bc080e7          	jalr	1980(ra) # 80004664 <end_op>
  p->cwd = ip;
    80005eb0:	16993023          	sd	s1,352(s2)
  return 0;
    80005eb4:	4501                	li	a0,0
}
    80005eb6:	60ea                	ld	ra,152(sp)
    80005eb8:	644a                	ld	s0,144(sp)
    80005eba:	64aa                	ld	s1,136(sp)
    80005ebc:	690a                	ld	s2,128(sp)
    80005ebe:	610d                	addi	sp,sp,160
    80005ec0:	8082                	ret
    end_op();
    80005ec2:	ffffe097          	auipc	ra,0xffffe
    80005ec6:	7a2080e7          	jalr	1954(ra) # 80004664 <end_op>
    return -1;
    80005eca:	557d                	li	a0,-1
    80005ecc:	b7ed                	j	80005eb6 <sys_chdir+0x7a>
    iunlockput(ip);
    80005ece:	8526                	mv	a0,s1
    80005ed0:	ffffe097          	auipc	ra,0xffffe
    80005ed4:	fac080e7          	jalr	-84(ra) # 80003e7c <iunlockput>
    end_op();
    80005ed8:	ffffe097          	auipc	ra,0xffffe
    80005edc:	78c080e7          	jalr	1932(ra) # 80004664 <end_op>
    return -1;
    80005ee0:	557d                	li	a0,-1
    80005ee2:	bfd1                	j	80005eb6 <sys_chdir+0x7a>

0000000080005ee4 <sys_exec>:

uint64
sys_exec(void)
{
    80005ee4:	7145                	addi	sp,sp,-464
    80005ee6:	e786                	sd	ra,456(sp)
    80005ee8:	e3a2                	sd	s0,448(sp)
    80005eea:	ff26                	sd	s1,440(sp)
    80005eec:	fb4a                	sd	s2,432(sp)
    80005eee:	f74e                	sd	s3,424(sp)
    80005ef0:	f352                	sd	s4,416(sp)
    80005ef2:	ef56                	sd	s5,408(sp)
    80005ef4:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005ef6:	e3840593          	addi	a1,s0,-456
    80005efa:	4505                	li	a0,1
    80005efc:	ffffd097          	auipc	ra,0xffffd
    80005f00:	144080e7          	jalr	324(ra) # 80003040 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005f04:	08000613          	li	a2,128
    80005f08:	f4040593          	addi	a1,s0,-192
    80005f0c:	4501                	li	a0,0
    80005f0e:	ffffd097          	auipc	ra,0xffffd
    80005f12:	152080e7          	jalr	338(ra) # 80003060 <argstr>
    80005f16:	87aa                	mv	a5,a0
    return -1;
    80005f18:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005f1a:	0c07c363          	bltz	a5,80005fe0 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005f1e:	10000613          	li	a2,256
    80005f22:	4581                	li	a1,0
    80005f24:	e4040513          	addi	a0,s0,-448
    80005f28:	ffffb097          	auipc	ra,0xffffb
    80005f2c:	daa080e7          	jalr	-598(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005f30:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005f34:	89a6                	mv	s3,s1
    80005f36:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005f38:	02000a13          	li	s4,32
    80005f3c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005f40:	00391513          	slli	a0,s2,0x3
    80005f44:	e3040593          	addi	a1,s0,-464
    80005f48:	e3843783          	ld	a5,-456(s0)
    80005f4c:	953e                	add	a0,a0,a5
    80005f4e:	ffffd097          	auipc	ra,0xffffd
    80005f52:	034080e7          	jalr	52(ra) # 80002f82 <fetchaddr>
    80005f56:	02054a63          	bltz	a0,80005f8a <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005f5a:	e3043783          	ld	a5,-464(s0)
    80005f5e:	c3b9                	beqz	a5,80005fa4 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f60:	ffffb097          	auipc	ra,0xffffb
    80005f64:	b86080e7          	jalr	-1146(ra) # 80000ae6 <kalloc>
    80005f68:	85aa                	mv	a1,a0
    80005f6a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f6e:	cd11                	beqz	a0,80005f8a <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f70:	6605                	lui	a2,0x1
    80005f72:	e3043503          	ld	a0,-464(s0)
    80005f76:	ffffd097          	auipc	ra,0xffffd
    80005f7a:	05e080e7          	jalr	94(ra) # 80002fd4 <fetchstr>
    80005f7e:	00054663          	bltz	a0,80005f8a <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005f82:	0905                	addi	s2,s2,1
    80005f84:	09a1                	addi	s3,s3,8
    80005f86:	fb491be3          	bne	s2,s4,80005f3c <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f8a:	f4040913          	addi	s2,s0,-192
    80005f8e:	6088                	ld	a0,0(s1)
    80005f90:	c539                	beqz	a0,80005fde <sys_exec+0xfa>
    kfree(argv[i]);
    80005f92:	ffffb097          	auipc	ra,0xffffb
    80005f96:	a56080e7          	jalr	-1450(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f9a:	04a1                	addi	s1,s1,8
    80005f9c:	ff2499e3          	bne	s1,s2,80005f8e <sys_exec+0xaa>
  return -1;
    80005fa0:	557d                	li	a0,-1
    80005fa2:	a83d                	j	80005fe0 <sys_exec+0xfc>
      argv[i] = 0;
    80005fa4:	0a8e                	slli	s5,s5,0x3
    80005fa6:	fc0a8793          	addi	a5,s5,-64
    80005faa:	00878ab3          	add	s5,a5,s0
    80005fae:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005fb2:	e4040593          	addi	a1,s0,-448
    80005fb6:	f4040513          	addi	a0,s0,-192
    80005fba:	fffff097          	auipc	ra,0xfffff
    80005fbe:	16e080e7          	jalr	366(ra) # 80005128 <exec>
    80005fc2:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fc4:	f4040993          	addi	s3,s0,-192
    80005fc8:	6088                	ld	a0,0(s1)
    80005fca:	c901                	beqz	a0,80005fda <sys_exec+0xf6>
    kfree(argv[i]);
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	a1c080e7          	jalr	-1508(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005fd4:	04a1                	addi	s1,s1,8
    80005fd6:	ff3499e3          	bne	s1,s3,80005fc8 <sys_exec+0xe4>
  return ret;
    80005fda:	854a                	mv	a0,s2
    80005fdc:	a011                	j	80005fe0 <sys_exec+0xfc>
  return -1;
    80005fde:	557d                	li	a0,-1
}
    80005fe0:	60be                	ld	ra,456(sp)
    80005fe2:	641e                	ld	s0,448(sp)
    80005fe4:	74fa                	ld	s1,440(sp)
    80005fe6:	795a                	ld	s2,432(sp)
    80005fe8:	79ba                	ld	s3,424(sp)
    80005fea:	7a1a                	ld	s4,416(sp)
    80005fec:	6afa                	ld	s5,408(sp)
    80005fee:	6179                	addi	sp,sp,464
    80005ff0:	8082                	ret

0000000080005ff2 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ff2:	7139                	addi	sp,sp,-64
    80005ff4:	fc06                	sd	ra,56(sp)
    80005ff6:	f822                	sd	s0,48(sp)
    80005ff8:	f426                	sd	s1,40(sp)
    80005ffa:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ffc:	ffffc097          	auipc	ra,0xffffc
    80006000:	a8e080e7          	jalr	-1394(ra) # 80001a8a <myproc>
    80006004:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006006:	fd840593          	addi	a1,s0,-40
    8000600a:	4501                	li	a0,0
    8000600c:	ffffd097          	auipc	ra,0xffffd
    80006010:	034080e7          	jalr	52(ra) # 80003040 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006014:	fc840593          	addi	a1,s0,-56
    80006018:	fd040513          	addi	a0,s0,-48
    8000601c:	fffff097          	auipc	ra,0xfffff
    80006020:	dc2080e7          	jalr	-574(ra) # 80004dde <pipealloc>
    return -1;
    80006024:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006026:	0c054463          	bltz	a0,800060ee <sys_pipe+0xfc>
  fd0 = -1;
    8000602a:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000602e:	fd043503          	ld	a0,-48(s0)
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	514080e7          	jalr	1300(ra) # 80005546 <fdalloc>
    8000603a:	fca42223          	sw	a0,-60(s0)
    8000603e:	08054b63          	bltz	a0,800060d4 <sys_pipe+0xe2>
    80006042:	fc843503          	ld	a0,-56(s0)
    80006046:	fffff097          	auipc	ra,0xfffff
    8000604a:	500080e7          	jalr	1280(ra) # 80005546 <fdalloc>
    8000604e:	fca42023          	sw	a0,-64(s0)
    80006052:	06054863          	bltz	a0,800060c2 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006056:	4691                	li	a3,4
    80006058:	fc440613          	addi	a2,s0,-60
    8000605c:	fd843583          	ld	a1,-40(s0)
    80006060:	70a8                	ld	a0,96(s1)
    80006062:	ffffb097          	auipc	ra,0xffffb
    80006066:	60a080e7          	jalr	1546(ra) # 8000166c <copyout>
    8000606a:	02054063          	bltz	a0,8000608a <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000606e:	4691                	li	a3,4
    80006070:	fc040613          	addi	a2,s0,-64
    80006074:	fd843583          	ld	a1,-40(s0)
    80006078:	0591                	addi	a1,a1,4
    8000607a:	70a8                	ld	a0,96(s1)
    8000607c:	ffffb097          	auipc	ra,0xffffb
    80006080:	5f0080e7          	jalr	1520(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006084:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006086:	06055463          	bgez	a0,800060ee <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000608a:	fc442783          	lw	a5,-60(s0)
    8000608e:	07f1                	addi	a5,a5,28
    80006090:	078e                	slli	a5,a5,0x3
    80006092:	97a6                	add	a5,a5,s1
    80006094:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006098:	fc042783          	lw	a5,-64(s0)
    8000609c:	07f1                	addi	a5,a5,28
    8000609e:	078e                	slli	a5,a5,0x3
    800060a0:	94be                	add	s1,s1,a5
    800060a2:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800060a6:	fd043503          	ld	a0,-48(s0)
    800060aa:	fffff097          	auipc	ra,0xfffff
    800060ae:	a04080e7          	jalr	-1532(ra) # 80004aae <fileclose>
    fileclose(wf);
    800060b2:	fc843503          	ld	a0,-56(s0)
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	9f8080e7          	jalr	-1544(ra) # 80004aae <fileclose>
    return -1;
    800060be:	57fd                	li	a5,-1
    800060c0:	a03d                	j	800060ee <sys_pipe+0xfc>
    if(fd0 >= 0)
    800060c2:	fc442783          	lw	a5,-60(s0)
    800060c6:	0007c763          	bltz	a5,800060d4 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800060ca:	07f1                	addi	a5,a5,28
    800060cc:	078e                	slli	a5,a5,0x3
    800060ce:	97a6                	add	a5,a5,s1
    800060d0:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    800060d4:	fd043503          	ld	a0,-48(s0)
    800060d8:	fffff097          	auipc	ra,0xfffff
    800060dc:	9d6080e7          	jalr	-1578(ra) # 80004aae <fileclose>
    fileclose(wf);
    800060e0:	fc843503          	ld	a0,-56(s0)
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	9ca080e7          	jalr	-1590(ra) # 80004aae <fileclose>
    return -1;
    800060ec:	57fd                	li	a5,-1
}
    800060ee:	853e                	mv	a0,a5
    800060f0:	70e2                	ld	ra,56(sp)
    800060f2:	7442                	ld	s0,48(sp)
    800060f4:	74a2                	ld	s1,40(sp)
    800060f6:	6121                	addi	sp,sp,64
    800060f8:	8082                	ret
    800060fa:	0000                	unimp
    800060fc:	0000                	unimp
	...

0000000080006100 <kernelvec>:
    80006100:	7111                	addi	sp,sp,-256
    80006102:	e006                	sd	ra,0(sp)
    80006104:	e40a                	sd	sp,8(sp)
    80006106:	e80e                	sd	gp,16(sp)
    80006108:	ec12                	sd	tp,24(sp)
    8000610a:	f016                	sd	t0,32(sp)
    8000610c:	f41a                	sd	t1,40(sp)
    8000610e:	f81e                	sd	t2,48(sp)
    80006110:	fc22                	sd	s0,56(sp)
    80006112:	e0a6                	sd	s1,64(sp)
    80006114:	e4aa                	sd	a0,72(sp)
    80006116:	e8ae                	sd	a1,80(sp)
    80006118:	ecb2                	sd	a2,88(sp)
    8000611a:	f0b6                	sd	a3,96(sp)
    8000611c:	f4ba                	sd	a4,104(sp)
    8000611e:	f8be                	sd	a5,112(sp)
    80006120:	fcc2                	sd	a6,120(sp)
    80006122:	e146                	sd	a7,128(sp)
    80006124:	e54a                	sd	s2,136(sp)
    80006126:	e94e                	sd	s3,144(sp)
    80006128:	ed52                	sd	s4,152(sp)
    8000612a:	f156                	sd	s5,160(sp)
    8000612c:	f55a                	sd	s6,168(sp)
    8000612e:	f95e                	sd	s7,176(sp)
    80006130:	fd62                	sd	s8,184(sp)
    80006132:	e1e6                	sd	s9,192(sp)
    80006134:	e5ea                	sd	s10,200(sp)
    80006136:	e9ee                	sd	s11,208(sp)
    80006138:	edf2                	sd	t3,216(sp)
    8000613a:	f1f6                	sd	t4,224(sp)
    8000613c:	f5fa                	sd	t5,232(sp)
    8000613e:	f9fe                	sd	t6,240(sp)
    80006140:	d0ffc0ef          	jal	ra,80002e4e <kerneltrap>
    80006144:	6082                	ld	ra,0(sp)
    80006146:	6122                	ld	sp,8(sp)
    80006148:	61c2                	ld	gp,16(sp)
    8000614a:	7282                	ld	t0,32(sp)
    8000614c:	7322                	ld	t1,40(sp)
    8000614e:	73c2                	ld	t2,48(sp)
    80006150:	7462                	ld	s0,56(sp)
    80006152:	6486                	ld	s1,64(sp)
    80006154:	6526                	ld	a0,72(sp)
    80006156:	65c6                	ld	a1,80(sp)
    80006158:	6666                	ld	a2,88(sp)
    8000615a:	7686                	ld	a3,96(sp)
    8000615c:	7726                	ld	a4,104(sp)
    8000615e:	77c6                	ld	a5,112(sp)
    80006160:	7866                	ld	a6,120(sp)
    80006162:	688a                	ld	a7,128(sp)
    80006164:	692a                	ld	s2,136(sp)
    80006166:	69ca                	ld	s3,144(sp)
    80006168:	6a6a                	ld	s4,152(sp)
    8000616a:	7a8a                	ld	s5,160(sp)
    8000616c:	7b2a                	ld	s6,168(sp)
    8000616e:	7bca                	ld	s7,176(sp)
    80006170:	7c6a                	ld	s8,184(sp)
    80006172:	6c8e                	ld	s9,192(sp)
    80006174:	6d2e                	ld	s10,200(sp)
    80006176:	6dce                	ld	s11,208(sp)
    80006178:	6e6e                	ld	t3,216(sp)
    8000617a:	7e8e                	ld	t4,224(sp)
    8000617c:	7f2e                	ld	t5,232(sp)
    8000617e:	7fce                	ld	t6,240(sp)
    80006180:	6111                	addi	sp,sp,256
    80006182:	10200073          	sret
    80006186:	00000013          	nop
    8000618a:	00000013          	nop
    8000618e:	0001                	nop

0000000080006190 <timervec>:
    80006190:	34051573          	csrrw	a0,mscratch,a0
    80006194:	e10c                	sd	a1,0(a0)
    80006196:	e510                	sd	a2,8(a0)
    80006198:	e914                	sd	a3,16(a0)
    8000619a:	6d0c                	ld	a1,24(a0)
    8000619c:	7110                	ld	a2,32(a0)
    8000619e:	6194                	ld	a3,0(a1)
    800061a0:	96b2                	add	a3,a3,a2
    800061a2:	e194                	sd	a3,0(a1)
    800061a4:	4589                	li	a1,2
    800061a6:	14459073          	csrw	sip,a1
    800061aa:	6914                	ld	a3,16(a0)
    800061ac:	6510                	ld	a2,8(a0)
    800061ae:	610c                	ld	a1,0(a0)
    800061b0:	34051573          	csrrw	a0,mscratch,a0
    800061b4:	30200073          	mret
	...

00000000800061ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ba:	1141                	addi	sp,sp,-16
    800061bc:	e422                	sd	s0,8(sp)
    800061be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061c0:	0c0007b7          	lui	a5,0xc000
    800061c4:	4705                	li	a4,1
    800061c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061c8:	c3d8                	sw	a4,4(a5)
}
    800061ca:	6422                	ld	s0,8(sp)
    800061cc:	0141                	addi	sp,sp,16
    800061ce:	8082                	ret

00000000800061d0 <plicinithart>:

void
plicinithart(void)
{
    800061d0:	1141                	addi	sp,sp,-16
    800061d2:	e406                	sd	ra,8(sp)
    800061d4:	e022                	sd	s0,0(sp)
    800061d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061d8:	ffffc097          	auipc	ra,0xffffc
    800061dc:	886080e7          	jalr	-1914(ra) # 80001a5e <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061e0:	0085171b          	slliw	a4,a0,0x8
    800061e4:	0c0027b7          	lui	a5,0xc002
    800061e8:	97ba                	add	a5,a5,a4
    800061ea:	40200713          	li	a4,1026
    800061ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061f2:	00d5151b          	slliw	a0,a0,0xd
    800061f6:	0c2017b7          	lui	a5,0xc201
    800061fa:	97aa                	add	a5,a5,a0
    800061fc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006200:	60a2                	ld	ra,8(sp)
    80006202:	6402                	ld	s0,0(sp)
    80006204:	0141                	addi	sp,sp,16
    80006206:	8082                	ret

0000000080006208 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006208:	1141                	addi	sp,sp,-16
    8000620a:	e406                	sd	ra,8(sp)
    8000620c:	e022                	sd	s0,0(sp)
    8000620e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006210:	ffffc097          	auipc	ra,0xffffc
    80006214:	84e080e7          	jalr	-1970(ra) # 80001a5e <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006218:	00d5151b          	slliw	a0,a0,0xd
    8000621c:	0c2017b7          	lui	a5,0xc201
    80006220:	97aa                	add	a5,a5,a0
  return irq;
}
    80006222:	43c8                	lw	a0,4(a5)
    80006224:	60a2                	ld	ra,8(sp)
    80006226:	6402                	ld	s0,0(sp)
    80006228:	0141                	addi	sp,sp,16
    8000622a:	8082                	ret

000000008000622c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000622c:	1101                	addi	sp,sp,-32
    8000622e:	ec06                	sd	ra,24(sp)
    80006230:	e822                	sd	s0,16(sp)
    80006232:	e426                	sd	s1,8(sp)
    80006234:	1000                	addi	s0,sp,32
    80006236:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006238:	ffffc097          	auipc	ra,0xffffc
    8000623c:	826080e7          	jalr	-2010(ra) # 80001a5e <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006240:	00d5151b          	slliw	a0,a0,0xd
    80006244:	0c2017b7          	lui	a5,0xc201
    80006248:	97aa                	add	a5,a5,a0
    8000624a:	c3c4                	sw	s1,4(a5)
}
    8000624c:	60e2                	ld	ra,24(sp)
    8000624e:	6442                	ld	s0,16(sp)
    80006250:	64a2                	ld	s1,8(sp)
    80006252:	6105                	addi	sp,sp,32
    80006254:	8082                	ret

0000000080006256 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006256:	1141                	addi	sp,sp,-16
    80006258:	e406                	sd	ra,8(sp)
    8000625a:	e022                	sd	s0,0(sp)
    8000625c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000625e:	479d                	li	a5,7
    80006260:	04a7cc63          	blt	a5,a0,800062b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006264:	0001c797          	auipc	a5,0x1c
    80006268:	efc78793          	addi	a5,a5,-260 # 80022160 <disk>
    8000626c:	97aa                	add	a5,a5,a0
    8000626e:	0187c783          	lbu	a5,24(a5)
    80006272:	ebb9                	bnez	a5,800062c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006274:	00451693          	slli	a3,a0,0x4
    80006278:	0001c797          	auipc	a5,0x1c
    8000627c:	ee878793          	addi	a5,a5,-280 # 80022160 <disk>
    80006280:	6398                	ld	a4,0(a5)
    80006282:	9736                	add	a4,a4,a3
    80006284:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006288:	6398                	ld	a4,0(a5)
    8000628a:	9736                	add	a4,a4,a3
    8000628c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006290:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006294:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006298:	97aa                	add	a5,a5,a0
    8000629a:	4705                	li	a4,1
    8000629c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800062a0:	0001c517          	auipc	a0,0x1c
    800062a4:	ed850513          	addi	a0,a0,-296 # 80022178 <disk+0x18>
    800062a8:	ffffc097          	auipc	ra,0xffffc
    800062ac:	228080e7          	jalr	552(ra) # 800024d0 <wakeup>
}
    800062b0:	60a2                	ld	ra,8(sp)
    800062b2:	6402                	ld	s0,0(sp)
    800062b4:	0141                	addi	sp,sp,16
    800062b6:	8082                	ret
    panic("free_desc 1");
    800062b8:	00002517          	auipc	a0,0x2
    800062bc:	57050513          	addi	a0,a0,1392 # 80008828 <syscalls+0x308>
    800062c0:	ffffa097          	auipc	ra,0xffffa
    800062c4:	280080e7          	jalr	640(ra) # 80000540 <panic>
    panic("free_desc 2");
    800062c8:	00002517          	auipc	a0,0x2
    800062cc:	57050513          	addi	a0,a0,1392 # 80008838 <syscalls+0x318>
    800062d0:	ffffa097          	auipc	ra,0xffffa
    800062d4:	270080e7          	jalr	624(ra) # 80000540 <panic>

00000000800062d8 <virtio_disk_init>:
{
    800062d8:	1101                	addi	sp,sp,-32
    800062da:	ec06                	sd	ra,24(sp)
    800062dc:	e822                	sd	s0,16(sp)
    800062de:	e426                	sd	s1,8(sp)
    800062e0:	e04a                	sd	s2,0(sp)
    800062e2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062e4:	00002597          	auipc	a1,0x2
    800062e8:	56458593          	addi	a1,a1,1380 # 80008848 <syscalls+0x328>
    800062ec:	0001c517          	auipc	a0,0x1c
    800062f0:	f9c50513          	addi	a0,a0,-100 # 80022288 <disk+0x128>
    800062f4:	ffffb097          	auipc	ra,0xffffb
    800062f8:	852080e7          	jalr	-1966(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062fc:	100017b7          	lui	a5,0x10001
    80006300:	4398                	lw	a4,0(a5)
    80006302:	2701                	sext.w	a4,a4
    80006304:	747277b7          	lui	a5,0x74727
    80006308:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000630c:	14f71b63          	bne	a4,a5,80006462 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006310:	100017b7          	lui	a5,0x10001
    80006314:	43dc                	lw	a5,4(a5)
    80006316:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006318:	4709                	li	a4,2
    8000631a:	14e79463          	bne	a5,a4,80006462 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000631e:	100017b7          	lui	a5,0x10001
    80006322:	479c                	lw	a5,8(a5)
    80006324:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006326:	12e79e63          	bne	a5,a4,80006462 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000632a:	100017b7          	lui	a5,0x10001
    8000632e:	47d8                	lw	a4,12(a5)
    80006330:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006332:	554d47b7          	lui	a5,0x554d4
    80006336:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000633a:	12f71463          	bne	a4,a5,80006462 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000633e:	100017b7          	lui	a5,0x10001
    80006342:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006346:	4705                	li	a4,1
    80006348:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000634a:	470d                	li	a4,3
    8000634c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000634e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006350:	c7ffe6b7          	lui	a3,0xc7ffe
    80006354:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc4bf>
    80006358:	8f75                	and	a4,a4,a3
    8000635a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000635c:	472d                	li	a4,11
    8000635e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006360:	5bbc                	lw	a5,112(a5)
    80006362:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006366:	8ba1                	andi	a5,a5,8
    80006368:	10078563          	beqz	a5,80006472 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000636c:	100017b7          	lui	a5,0x10001
    80006370:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006374:	43fc                	lw	a5,68(a5)
    80006376:	2781                	sext.w	a5,a5
    80006378:	10079563          	bnez	a5,80006482 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000637c:	100017b7          	lui	a5,0x10001
    80006380:	5bdc                	lw	a5,52(a5)
    80006382:	2781                	sext.w	a5,a5
  if(max == 0)
    80006384:	10078763          	beqz	a5,80006492 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006388:	471d                	li	a4,7
    8000638a:	10f77c63          	bgeu	a4,a5,800064a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000638e:	ffffa097          	auipc	ra,0xffffa
    80006392:	758080e7          	jalr	1880(ra) # 80000ae6 <kalloc>
    80006396:	0001c497          	auipc	s1,0x1c
    8000639a:	dca48493          	addi	s1,s1,-566 # 80022160 <disk>
    8000639e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800063a0:	ffffa097          	auipc	ra,0xffffa
    800063a4:	746080e7          	jalr	1862(ra) # 80000ae6 <kalloc>
    800063a8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	73c080e7          	jalr	1852(ra) # 80000ae6 <kalloc>
    800063b2:	87aa                	mv	a5,a0
    800063b4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800063b6:	6088                	ld	a0,0(s1)
    800063b8:	cd6d                	beqz	a0,800064b2 <virtio_disk_init+0x1da>
    800063ba:	0001c717          	auipc	a4,0x1c
    800063be:	dae73703          	ld	a4,-594(a4) # 80022168 <disk+0x8>
    800063c2:	cb65                	beqz	a4,800064b2 <virtio_disk_init+0x1da>
    800063c4:	c7fd                	beqz	a5,800064b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800063c6:	6605                	lui	a2,0x1
    800063c8:	4581                	li	a1,0
    800063ca:	ffffb097          	auipc	ra,0xffffb
    800063ce:	908080e7          	jalr	-1784(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800063d2:	0001c497          	auipc	s1,0x1c
    800063d6:	d8e48493          	addi	s1,s1,-626 # 80022160 <disk>
    800063da:	6605                	lui	a2,0x1
    800063dc:	4581                	li	a1,0
    800063de:	6488                	ld	a0,8(s1)
    800063e0:	ffffb097          	auipc	ra,0xffffb
    800063e4:	8f2080e7          	jalr	-1806(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800063e8:	6605                	lui	a2,0x1
    800063ea:	4581                	li	a1,0
    800063ec:	6888                	ld	a0,16(s1)
    800063ee:	ffffb097          	auipc	ra,0xffffb
    800063f2:	8e4080e7          	jalr	-1820(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063f6:	100017b7          	lui	a5,0x10001
    800063fa:	4721                	li	a4,8
    800063fc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800063fe:	4098                	lw	a4,0(s1)
    80006400:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006404:	40d8                	lw	a4,4(s1)
    80006406:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000640a:	6498                	ld	a4,8(s1)
    8000640c:	0007069b          	sext.w	a3,a4
    80006410:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006414:	9701                	srai	a4,a4,0x20
    80006416:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000641a:	6898                	ld	a4,16(s1)
    8000641c:	0007069b          	sext.w	a3,a4
    80006420:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006424:	9701                	srai	a4,a4,0x20
    80006426:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000642a:	4705                	li	a4,1
    8000642c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000642e:	00e48c23          	sb	a4,24(s1)
    80006432:	00e48ca3          	sb	a4,25(s1)
    80006436:	00e48d23          	sb	a4,26(s1)
    8000643a:	00e48da3          	sb	a4,27(s1)
    8000643e:	00e48e23          	sb	a4,28(s1)
    80006442:	00e48ea3          	sb	a4,29(s1)
    80006446:	00e48f23          	sb	a4,30(s1)
    8000644a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000644e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006452:	0727a823          	sw	s2,112(a5)
}
    80006456:	60e2                	ld	ra,24(sp)
    80006458:	6442                	ld	s0,16(sp)
    8000645a:	64a2                	ld	s1,8(sp)
    8000645c:	6902                	ld	s2,0(sp)
    8000645e:	6105                	addi	sp,sp,32
    80006460:	8082                	ret
    panic("could not find virtio disk");
    80006462:	00002517          	auipc	a0,0x2
    80006466:	3f650513          	addi	a0,a0,1014 # 80008858 <syscalls+0x338>
    8000646a:	ffffa097          	auipc	ra,0xffffa
    8000646e:	0d6080e7          	jalr	214(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006472:	00002517          	auipc	a0,0x2
    80006476:	40650513          	addi	a0,a0,1030 # 80008878 <syscalls+0x358>
    8000647a:	ffffa097          	auipc	ra,0xffffa
    8000647e:	0c6080e7          	jalr	198(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006482:	00002517          	auipc	a0,0x2
    80006486:	41650513          	addi	a0,a0,1046 # 80008898 <syscalls+0x378>
    8000648a:	ffffa097          	auipc	ra,0xffffa
    8000648e:	0b6080e7          	jalr	182(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006492:	00002517          	auipc	a0,0x2
    80006496:	42650513          	addi	a0,a0,1062 # 800088b8 <syscalls+0x398>
    8000649a:	ffffa097          	auipc	ra,0xffffa
    8000649e:	0a6080e7          	jalr	166(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800064a2:	00002517          	auipc	a0,0x2
    800064a6:	43650513          	addi	a0,a0,1078 # 800088d8 <syscalls+0x3b8>
    800064aa:	ffffa097          	auipc	ra,0xffffa
    800064ae:	096080e7          	jalr	150(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800064b2:	00002517          	auipc	a0,0x2
    800064b6:	44650513          	addi	a0,a0,1094 # 800088f8 <syscalls+0x3d8>
    800064ba:	ffffa097          	auipc	ra,0xffffa
    800064be:	086080e7          	jalr	134(ra) # 80000540 <panic>

00000000800064c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800064c2:	7119                	addi	sp,sp,-128
    800064c4:	fc86                	sd	ra,120(sp)
    800064c6:	f8a2                	sd	s0,112(sp)
    800064c8:	f4a6                	sd	s1,104(sp)
    800064ca:	f0ca                	sd	s2,96(sp)
    800064cc:	ecce                	sd	s3,88(sp)
    800064ce:	e8d2                	sd	s4,80(sp)
    800064d0:	e4d6                	sd	s5,72(sp)
    800064d2:	e0da                	sd	s6,64(sp)
    800064d4:	fc5e                	sd	s7,56(sp)
    800064d6:	f862                	sd	s8,48(sp)
    800064d8:	f466                	sd	s9,40(sp)
    800064da:	f06a                	sd	s10,32(sp)
    800064dc:	ec6e                	sd	s11,24(sp)
    800064de:	0100                	addi	s0,sp,128
    800064e0:	8aaa                	mv	s5,a0
    800064e2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800064e4:	00c52d03          	lw	s10,12(a0)
    800064e8:	001d1d1b          	slliw	s10,s10,0x1
    800064ec:	1d02                	slli	s10,s10,0x20
    800064ee:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800064f2:	0001c517          	auipc	a0,0x1c
    800064f6:	d9650513          	addi	a0,a0,-618 # 80022288 <disk+0x128>
    800064fa:	ffffa097          	auipc	ra,0xffffa
    800064fe:	6dc080e7          	jalr	1756(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006502:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006504:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006506:	0001cb97          	auipc	s7,0x1c
    8000650a:	c5ab8b93          	addi	s7,s7,-934 # 80022160 <disk>
  for(int i = 0; i < 3; i++){
    8000650e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006510:	0001cc97          	auipc	s9,0x1c
    80006514:	d78c8c93          	addi	s9,s9,-648 # 80022288 <disk+0x128>
    80006518:	a08d                	j	8000657a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000651a:	00fb8733          	add	a4,s7,a5
    8000651e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006522:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006524:	0207c563          	bltz	a5,8000654e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006528:	2905                	addiw	s2,s2,1
    8000652a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000652c:	05690c63          	beq	s2,s6,80006584 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006530:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006532:	0001c717          	auipc	a4,0x1c
    80006536:	c2e70713          	addi	a4,a4,-978 # 80022160 <disk>
    8000653a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000653c:	01874683          	lbu	a3,24(a4)
    80006540:	fee9                	bnez	a3,8000651a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006542:	2785                	addiw	a5,a5,1
    80006544:	0705                	addi	a4,a4,1
    80006546:	fe979be3          	bne	a5,s1,8000653c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000654a:	57fd                	li	a5,-1
    8000654c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000654e:	01205d63          	blez	s2,80006568 <virtio_disk_rw+0xa6>
    80006552:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006554:	000a2503          	lw	a0,0(s4)
    80006558:	00000097          	auipc	ra,0x0
    8000655c:	cfe080e7          	jalr	-770(ra) # 80006256 <free_desc>
      for(int j = 0; j < i; j++)
    80006560:	2d85                	addiw	s11,s11,1
    80006562:	0a11                	addi	s4,s4,4
    80006564:	ff2d98e3          	bne	s11,s2,80006554 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006568:	85e6                	mv	a1,s9
    8000656a:	0001c517          	auipc	a0,0x1c
    8000656e:	c0e50513          	addi	a0,a0,-1010 # 80022178 <disk+0x18>
    80006572:	ffffc097          	auipc	ra,0xffffc
    80006576:	efa080e7          	jalr	-262(ra) # 8000246c <sleep>
  for(int i = 0; i < 3; i++){
    8000657a:	f8040a13          	addi	s4,s0,-128
{
    8000657e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006580:	894e                	mv	s2,s3
    80006582:	b77d                	j	80006530 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006584:	f8042503          	lw	a0,-128(s0)
    80006588:	00a50713          	addi	a4,a0,10
    8000658c:	0712                	slli	a4,a4,0x4

  if(write)
    8000658e:	0001c797          	auipc	a5,0x1c
    80006592:	bd278793          	addi	a5,a5,-1070 # 80022160 <disk>
    80006596:	00e786b3          	add	a3,a5,a4
    8000659a:	01803633          	snez	a2,s8
    8000659e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800065a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800065a4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800065a8:	f6070613          	addi	a2,a4,-160
    800065ac:	6394                	ld	a3,0(a5)
    800065ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800065b0:	00870593          	addi	a1,a4,8
    800065b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800065b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800065b8:	0007b803          	ld	a6,0(a5)
    800065bc:	9642                	add	a2,a2,a6
    800065be:	46c1                	li	a3,16
    800065c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800065c2:	4585                	li	a1,1
    800065c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800065c8:	f8442683          	lw	a3,-124(s0)
    800065cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800065d0:	0692                	slli	a3,a3,0x4
    800065d2:	9836                	add	a6,a6,a3
    800065d4:	058a8613          	addi	a2,s5,88
    800065d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800065dc:	0007b803          	ld	a6,0(a5)
    800065e0:	96c2                	add	a3,a3,a6
    800065e2:	40000613          	li	a2,1024
    800065e6:	c690                	sw	a2,8(a3)
  if(write)
    800065e8:	001c3613          	seqz	a2,s8
    800065ec:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065f0:	00166613          	ori	a2,a2,1
    800065f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065f8:	f8842603          	lw	a2,-120(s0)
    800065fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006600:	00250693          	addi	a3,a0,2
    80006604:	0692                	slli	a3,a3,0x4
    80006606:	96be                	add	a3,a3,a5
    80006608:	58fd                	li	a7,-1
    8000660a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000660e:	0612                	slli	a2,a2,0x4
    80006610:	9832                	add	a6,a6,a2
    80006612:	f9070713          	addi	a4,a4,-112
    80006616:	973e                	add	a4,a4,a5
    80006618:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000661c:	6398                	ld	a4,0(a5)
    8000661e:	9732                	add	a4,a4,a2
    80006620:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006622:	4609                	li	a2,2
    80006624:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006628:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000662c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006630:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006634:	6794                	ld	a3,8(a5)
    80006636:	0026d703          	lhu	a4,2(a3)
    8000663a:	8b1d                	andi	a4,a4,7
    8000663c:	0706                	slli	a4,a4,0x1
    8000663e:	96ba                	add	a3,a3,a4
    80006640:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006644:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006648:	6798                	ld	a4,8(a5)
    8000664a:	00275783          	lhu	a5,2(a4)
    8000664e:	2785                	addiw	a5,a5,1
    80006650:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006654:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006658:	100017b7          	lui	a5,0x10001
    8000665c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006660:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006664:	0001c917          	auipc	s2,0x1c
    80006668:	c2490913          	addi	s2,s2,-988 # 80022288 <disk+0x128>
  while(b->disk == 1) {
    8000666c:	4485                	li	s1,1
    8000666e:	00b79c63          	bne	a5,a1,80006686 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006672:	85ca                	mv	a1,s2
    80006674:	8556                	mv	a0,s5
    80006676:	ffffc097          	auipc	ra,0xffffc
    8000667a:	df6080e7          	jalr	-522(ra) # 8000246c <sleep>
  while(b->disk == 1) {
    8000667e:	004aa783          	lw	a5,4(s5)
    80006682:	fe9788e3          	beq	a5,s1,80006672 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006686:	f8042903          	lw	s2,-128(s0)
    8000668a:	00290713          	addi	a4,s2,2
    8000668e:	0712                	slli	a4,a4,0x4
    80006690:	0001c797          	auipc	a5,0x1c
    80006694:	ad078793          	addi	a5,a5,-1328 # 80022160 <disk>
    80006698:	97ba                	add	a5,a5,a4
    8000669a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000669e:	0001c997          	auipc	s3,0x1c
    800066a2:	ac298993          	addi	s3,s3,-1342 # 80022160 <disk>
    800066a6:	00491713          	slli	a4,s2,0x4
    800066aa:	0009b783          	ld	a5,0(s3)
    800066ae:	97ba                	add	a5,a5,a4
    800066b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800066b4:	854a                	mv	a0,s2
    800066b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066ba:	00000097          	auipc	ra,0x0
    800066be:	b9c080e7          	jalr	-1124(ra) # 80006256 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066c2:	8885                	andi	s1,s1,1
    800066c4:	f0ed                	bnez	s1,800066a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066c6:	0001c517          	auipc	a0,0x1c
    800066ca:	bc250513          	addi	a0,a0,-1086 # 80022288 <disk+0x128>
    800066ce:	ffffa097          	auipc	ra,0xffffa
    800066d2:	5bc080e7          	jalr	1468(ra) # 80000c8a <release>
}
    800066d6:	70e6                	ld	ra,120(sp)
    800066d8:	7446                	ld	s0,112(sp)
    800066da:	74a6                	ld	s1,104(sp)
    800066dc:	7906                	ld	s2,96(sp)
    800066de:	69e6                	ld	s3,88(sp)
    800066e0:	6a46                	ld	s4,80(sp)
    800066e2:	6aa6                	ld	s5,72(sp)
    800066e4:	6b06                	ld	s6,64(sp)
    800066e6:	7be2                	ld	s7,56(sp)
    800066e8:	7c42                	ld	s8,48(sp)
    800066ea:	7ca2                	ld	s9,40(sp)
    800066ec:	7d02                	ld	s10,32(sp)
    800066ee:	6de2                	ld	s11,24(sp)
    800066f0:	6109                	addi	sp,sp,128
    800066f2:	8082                	ret

00000000800066f4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066f4:	1101                	addi	sp,sp,-32
    800066f6:	ec06                	sd	ra,24(sp)
    800066f8:	e822                	sd	s0,16(sp)
    800066fa:	e426                	sd	s1,8(sp)
    800066fc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066fe:	0001c497          	auipc	s1,0x1c
    80006702:	a6248493          	addi	s1,s1,-1438 # 80022160 <disk>
    80006706:	0001c517          	auipc	a0,0x1c
    8000670a:	b8250513          	addi	a0,a0,-1150 # 80022288 <disk+0x128>
    8000670e:	ffffa097          	auipc	ra,0xffffa
    80006712:	4c8080e7          	jalr	1224(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006716:	10001737          	lui	a4,0x10001
    8000671a:	533c                	lw	a5,96(a4)
    8000671c:	8b8d                	andi	a5,a5,3
    8000671e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006720:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006724:	689c                	ld	a5,16(s1)
    80006726:	0204d703          	lhu	a4,32(s1)
    8000672a:	0027d783          	lhu	a5,2(a5)
    8000672e:	04f70863          	beq	a4,a5,8000677e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006732:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006736:	6898                	ld	a4,16(s1)
    80006738:	0204d783          	lhu	a5,32(s1)
    8000673c:	8b9d                	andi	a5,a5,7
    8000673e:	078e                	slli	a5,a5,0x3
    80006740:	97ba                	add	a5,a5,a4
    80006742:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006744:	00278713          	addi	a4,a5,2
    80006748:	0712                	slli	a4,a4,0x4
    8000674a:	9726                	add	a4,a4,s1
    8000674c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006750:	e721                	bnez	a4,80006798 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006752:	0789                	addi	a5,a5,2
    80006754:	0792                	slli	a5,a5,0x4
    80006756:	97a6                	add	a5,a5,s1
    80006758:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000675a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000675e:	ffffc097          	auipc	ra,0xffffc
    80006762:	d72080e7          	jalr	-654(ra) # 800024d0 <wakeup>

    disk.used_idx += 1;
    80006766:	0204d783          	lhu	a5,32(s1)
    8000676a:	2785                	addiw	a5,a5,1
    8000676c:	17c2                	slli	a5,a5,0x30
    8000676e:	93c1                	srli	a5,a5,0x30
    80006770:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006774:	6898                	ld	a4,16(s1)
    80006776:	00275703          	lhu	a4,2(a4)
    8000677a:	faf71ce3          	bne	a4,a5,80006732 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000677e:	0001c517          	auipc	a0,0x1c
    80006782:	b0a50513          	addi	a0,a0,-1270 # 80022288 <disk+0x128>
    80006786:	ffffa097          	auipc	ra,0xffffa
    8000678a:	504080e7          	jalr	1284(ra) # 80000c8a <release>
}
    8000678e:	60e2                	ld	ra,24(sp)
    80006790:	6442                	ld	s0,16(sp)
    80006792:	64a2                	ld	s1,8(sp)
    80006794:	6105                	addi	sp,sp,32
    80006796:	8082                	ret
      panic("virtio_disk_intr status");
    80006798:	00002517          	auipc	a0,0x2
    8000679c:	17850513          	addi	a0,a0,376 # 80008910 <syscalls+0x3f0>
    800067a0:	ffffa097          	auipc	ra,0xffffa
    800067a4:	da0080e7          	jalr	-608(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
