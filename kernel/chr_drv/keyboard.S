/* passed
* linux/kernel/keyboard.S
*
* (C) 1991 Linus Torvalds
*/
.586p
.model flat
/*
* Thanks to Alfred Leung for US keyboard patches
* Wolfgang Thiel for German keyboard patches
* Marc Corsini for the French keyboard
*/
/*
* ��лAlfred Leung ������US ���̲�������
* Wolfgang Thiel �����˵�����̲�������
* Marc Corsini �����˷��ļ��̲�������
*/

#include <linux/config.h> // �ں�����ͷ�ļ�������������Ժ�Ӳ�����ͣ�HD_TYPE����ѡ�

extern _do_tty_interrupt:proc, _show_stat:proc
extern _table_list:dword
public _keyboard_interrupt //int 21h ��console.c�ڵ�conn_init����������

/*
* these are for the keyboard read functions
*/
/*
* ������Щ�����ڼ��̶�������
*/
// bsize �Ǽ��̻������ĳ��ȣ��ֽ�������
bsize = 1024 /* must be a power of two ! And MUST be the same
			as in tty_io.c !!!! */
			/* ��ֵ������2 �Ĵη���������tty_io.c �е�ֵƥ��!!!! */
			// ������Щ�ǻ�����нṹ�е�ƫ���� */
head = 4 // ��������ͷָ���ֶ�ƫ�ơ�
tail = 8 // ��������βָ���ֶ�ƫ�ơ�
proc_list = 12 // �ȴ��û�����еĽ����ֶ�ƫ�ơ�
buf = 16 // �������ֶ�ƫ�ơ�

.code

mode db 0 /* caps, alt, ctrl and shift mode */
// mode �Ǽ���������İ���״̬��־��
// ��ʾ��Сдת����(caps)��������(alt)�����Ƽ�(ctrl)�ͻ�����(shift)��״̬��
// λ7 caps �����£�
// λ6 caps ����״̬(Ӧ����leds �еĶ�Ӧ��־λһ��)��
// λ5 ��alt �����£�
// λ4 ��alt �����£�
// λ3 ��ctrl �����£�
// λ2 ��ctrl �����£�
// λ1 ��shift �����£�
// λ0 ��shift �����¡�

leds db 2 /* num-lock, caps, scroll-lock mode (nom-lock on) */
// ����������(num-lock)����Сдת����(caps-lock)�͹���������(scroll-lock)��LED �����״̬��
// λ7-3 ȫ0 ���ã�
// λ2 caps-lock��
// λ1 num-lock(��ʼ��1��Ҳ����������������(num-lock)�����Ϊ��)��
// λ0 scroll-lock��

e0 db 0
// ��ɨ������0xe0 ��0xe1 ʱ���øñ�־����ʾ��󻹸�����1 ����2 ���ַ�ɨ���룬�μ��б���˵����
// λ1 =1 �յ�0xe1 ��־��
// λ0 =1 �յ�0xe0 ��־��
/*
* con_int is the real interrupt routine that reads the
* keyboard scan-code and converts it into the appropriate
* ascii character(s).
*/
/*
* con_int ��ʵ�ʵ��жϴ����ӳ������ڶ�����ɨ���벢����ת��
* ����Ӧ��ascii �ַ���
*/
//// �����ж�int 21h����������ڵ㡣
_keyboard_interrupt:
	push eax
	push ebx
	push ecx
	push edx
	push ds
	push es
	mov eax,10h // ��ds��es �μĴ�����Ϊ�ں����ݶΡ�
	mov ds,ax
	mov es,ax
	xor al,al /* %eax is scan code */ /* eax ����ɨ���� */
	in al,60h // ��ȡɨ����->al��
	cmp al,0e0h // ��ɨ������0xe0 �����������ת������e0 ��־���봦��
	je set_e0
	cmp al,0e1h // ɨ������0xe1 �����������ת������e1 ��־���봦��
	je set_e1
	call key_table[eax*4] // ���ü���������ker_table + eax * 4���μ�����502 �У���
	mov e0,0 // ��λe0 ��־��
// ������δ���(55-65 ��)�����ʹ��8255A ��PC ��׼���̵�·����Ӳ����λ�������˿�0x61 ��
// 8255A �����B �ĵ�ַ��������˿ڵĵ�7 λ(PB7)���ڽ�ֹ�������Լ������ݵĴ�����
// ��γ������ڶ��յ���ɨ��������Ӧ�𡣷��������Ƚ�ֹ���̣�Ȼ�����������������̹�����
e0_e1: 
	in al,61h // ȡPPI �˿�B ״̬����λ7 ��������/��ֹ(0/1)���̡�
	jmp l1 // �ӳ�һ�ᡣ
l1: jmp l2
l2: or al,80h // al λ7 ��λ(��ֹ���̹���)��
	jmp l3 // ���ӳ�һ�ᡣ
l3: jmp l4
l4: out 61h,al // ʹPPI PB7 λ��λ��
	jmp l5 // �ӳ�һ�ᡣ
l5: jmp l6
l6: and al,7Fh // al λ7 ��λ��
	out 61h,al // ʹPPI PB7 λ��λ���������̹�������
	mov al,20h // ��8259 �ж�оƬ����EOI(�жϽ���)�źš�
	out 20h,al
	push 0 // ����̨tty ��=0����Ϊ������ջ��
	call _do_tty_interrupt // ���յ������ݸ��Ƴɹ淶ģʽ���ݲ�����ڹ淶�ַ���������С�
	add esp,4 // ������ջ�Ĳ��������������ļĴ��������жϷ��ء�
	pop es
	pop ds
	pop edx
	pop ecx
	pop ebx
	pop eax
	iretd
set_e0: 
	mov e0,1 // �յ�ɨ��ǰ����0xe0 ʱ������e0 ��־��λ0����
	jmp e0_e1
set_e1: 
	mov e0,2 // �յ�ɨ��ǰ����0xe1 ʱ������e1 ��־��λ1����
	jmp e0_e1

/*
* ������ӳ����ebx:eax �е����8 ���ַ����뻺������С�(edx ��
* ��д���ַ���˳����al,ah,eal,eah,bl,bh...ֱ��eax ����0��
*/
put_queue:
	push ecx // ����ecx��edx ���ݡ�
	push edx // ȡ����̨tty �ṹ�ж��������ָ�롣
	mov edx,_table_list // read-queue for console
	mov ecx,head[edx] // ȡ���������ͷָ��->ecx��
l7: mov buf[edx+ecx],al // ��al �е��ַ����뻺�����ͷָ��λ�ô���
	inc ecx // ͷָ��ǰ��1 �ֽڡ�
	and ecx,bsize-1 // �Ի�������С����ͷָ��(�������򷵻ػ�������ʼ)��
	cmp ecx,tail[edx] // buffer full - discard everything
// ͷָ��==βָ����(���������)��
	je l9 // ��������������δ������ַ�ȫ������
	shrd eax,ebx,8 // ��ebx ��8 λ����λ����8 λ��eax �У���ebx ���䡣
	je l8 // �����ַ�����û��(����0)����ת��
	shr ebx,8 // ��ebx �б���λ����8 λ������ת�����l7 ����������
	jmp l7
l8: mov head[edx],ecx // ���ѽ������ַ��������˶��У��򱣴�ͷָ�롣
	mov ecx,proc_list[edx] // �ö��еĵȴ�����ָ�룿
	test ecx,ecx // �������ṹָ���Ƿ�Ϊ��(�еȴ��ö��еĽ�����)��
	je l9 // �ޣ�����ת��
	mov dword ptr [ecx],0 // �У����øý���Ϊ�����о���״̬(���Ѹý���)��
l9: pop edx // ���������ļĴ��������ء�
	pop ecx
	ret

// ������δ������ctrl ��alt ��ɨ���룬�ֱ�����ģʽ��־����Ӧλ�������ɨ����֮ǰ�յ���
// 0xe0 ɨ����(e0 ��־��λ)����˵�����µ��Ǽ����ұߵ�ctrl ��alt �������Ӧ����ctrl ��alt
// ��ģʽ��־mode �еı���λ��
ctrl:
	mov al,04h // 0x4 ��ģʽ��־mode ����ctrl ����Ӧ�ı���λ(λ2)��
	jmp l10
alt:
	mov al,10h // 0x10 ��ģʽ��־mode ����alt ����Ӧ�ı���λ(λ4)��
l10:
	cmp e0,0 // e0 ��־��λ����(���µ����ұߵ�ctrl ��alt ����)��
	je l11 // ������ת��
	add al,al // �ǣ���ĳ�����Ӧ�Ҽ��ı�־λ(λ3 ��λ5)��
l11:
	or mode,al // ����ģʽ��־mode �ж�Ӧ�ı���λ��
	ret
// ��δ��봦��ctrl ��alt ���ɿ���ɨ���룬��Ӧ��λģʽ��־mode �еı���λ���ڴ���ʱҪ����
// e0 ��־�Ƿ���λ���ж��Ƿ��Ǽ����ұߵ�ctrl ��alt ����
unctrl:
	mov al,04h // ģʽ��־mode ����ctrl ����Ӧ�ı���λ(λ2)��
	jmp l12
unalt:
	mov al,10h // 0x10 ��ģʽ��־mode ����alt ����Ӧ�ı���λ(λ4)��
l12:
	cmp e0,0 // e0 ��־��λ����(�ͷŵ����ұߵ�ctrl ��alt ����)��
	je l13 // ���ǣ���ת��
	add al,al // �ǣ���óɸ�λ��Ӧ�Ҽ��ı�־λ(λ3 ��λ5)��
l13:
	not al // ��λģʽ��־mode �ж�Ӧ�ı���λ��
	and mode,al
	ret

lshift:
	or mode,01h // ����shift �����£�����mode �ж�Ӧ�ı�־λ(λ0)��
	ret
unlshift:
	and mode,0feh // ����shift ���ɿ�����λmode �ж�Ӧ�ı�־λ(λ0)��
	ret
rshift:
	or mode,02h // ����shift �����£�����mode �ж�Ӧ�ı�־λ(λ1)��
	ret
unrshift:
	and mode,0fdh // ����shift ���ɿ�����λmode �ж�Ӧ�ı�־λ(λ1)��
	ret

caps:
	test mode,80h // ����ģʽ��־mode ��λ7 �Ƿ��Ѿ���λ(����״̬)��
	jne l14 // ����Ѵ��ڰ���״̬���򷵻�(ret)��
	xor leds,4 // ��תleds ��־��caps-lock ����λ(λ2)��
	xor mode,40h // ��תmode ��־��caps �����µı���λ(λ6)��
	or mode,80h // ����mode ��־��caps ���Ѱ��±�־λ(λ7)��
// ��δ������leds ��־��������ر�LED ָʾ����
set_leds:
	call kb_wait // �ȴ����̿��������뻺��ա�
	mov al,0edh /* set leds command */ /* ����LED ������ */
	out 60h,al // ���ͼ�������0xed ��0x60 �˿ڡ�
	call kb_wait // �ȴ����̿��������뻺��ա�
	mov al,leds // ȡleds ��־����Ϊ������
	out 60h,al // ���͸ò�����
	ret
uncaps:
	and mode,7fh // caps ���ɿ�����λģʽ��־mode �еĶ�Ӧλ(λ7)��
	ret
scroll:
	xor leds,1 // scroll �����£���תleds ��־�еĶ�Ӧλ(λ0)��
	jmp set_leds // ����leds ��־���¿�����ر�LED ָʾ����
num:
	xor leds,2 // num �����£���תleds ��־�еĶ�Ӧλ(λ1)��
	jmp set_leds // ����leds ��־���¿�����ر�LED ָʾ����

/*
* curosr-key/numeric keypad cursor keys are handled here.
* checking for numeric keypad etc.
*/
/*
* ���ﴦ�������/����С���̷�������������С���̵ȡ�
*/
cursor:
	sub al,47h // ɨ������С���ּ����ϵļ�(��ɨ����>=0x47)�����ģ�
	jb l14 // ���С���򲻴��������ء�
	cmp al,12 // ���ɨ���� > 0x53(0x53 - 0x47= 12)����
	ja l14 // ɨ����ֵ����83(0x53)�������������ء�
	jne cur2 /* check for ctrl-alt-del */ /* ����Ƿ�ctrl-alt-del */
// �������12����˵��del ���ѱ����£�������ж�ctrl
// ��alt �Ƿ�Ҳͬʱ���¡�
	test mode,0ch // ��ctrl ��������
	je cur2 // �ޣ�����ת��
	test mode,30h // ��alt ��������
	jne reboot // �У�����ת��������������
cur2:
	cmp e0,01h /* e0 forces cursor movement */ /* e0 ��λ��ʾ����ƶ� */
// e0 ��־��λ����
	je cur // ��λ�ˣ�����ת����ƶ�������cur��
	test leds,02h /* not num-lock forces cursor */ /* num-lock ������ */
// ����leds �б�־num-lock ����־�Ƿ���λ��
	je cur // ���û����λ(num ��LED ����)����Ҳ���й���ƶ�������
	test mode,03h /* shift forces cursor */ /* shift ��Ҳʹ����ƶ� */
// ����ģʽ��־mode ��shift ���±�־��
	jne cur // �����shift �����£���Ҳ���й���ƶ�������
	xor ebx,ebx // �����ѯɨ���ֱ�(199 ��)��ȡ��Ӧ��������ASCII �롣
	mov al,num_table[eax] // ��eax ��Ϊ����ֵ��ȡ��Ӧ�����ַ�->al��
	jmp put_queue // �����ַ����뻺������С�
l14:
	ret

// ��δ��봦�������ƶ���
cur:
	mov al,cur_table[eax] // ȡ����ַ�������Ӧ���Ĵ����ַ�??al��
	cmp al,'9' // �����ַ�<='9'��˵������һҳ����һҳ�������ɾ������
	ja ok_cur // �����ַ�������Ҫ�����ַ�'~'��
	mov ah,'~'
ok_cur:
	shl eax,16 // ��ax �������Ƶ�eax �����С�
	mov ax,5b1bh // ��ax �з���'esc ['�ַ�����eax �������ַ�����ƶ����С�
	xor ebx,ebx
	jmp put_queue // �����ַ����뻺������С�

#if defined(KBD_FR)
num_table db "789 456 1230." // ����С�����ϼ���Ӧ������ASCII �����
#else
num_table db "789 456 1230,"
#endif
cur_table db  "HA5 DGC YB623" // ����С�����Ϸ���������ɾ������Ӧ���ƶ���ʾ�ַ�����

/*
* this routine handles function keys
*/
// �����ӳ��������ܼ���
func:
	push eax
	push ecx
	push edx
	call _show_stat // ������ʾ������״̬����(kernl/sched.c, 37)��
	pop edx
	pop ecx
	pop eax
	sub al,3Bh // ���ܼ�'F1'��ɨ������0x3B����˴�ʱal ���ǹ��ܼ������š�
	jb end_func // ���ɨ����С��0x3b���򲻴��������ء�
	cmp al,9 // ���ܼ���F1-F10��
	jbe ok_func // �ǣ�����ת��
	sub al,18 // �ǹ��ܼ�F11��F12 ��
	cmp al,10 // �ǹ��ܼ�F11��
	jb end_func // ���ǣ��򲻴��������ء�
	cmp al,11 // �ǹ��ܼ�F12��
	ja end_func // ���ǣ��򲻴��������ء�
ok_func:
	cmp ecx,4 /* check that there is enough room */ /* ����Ƿ����㹻�ռ�*/
	jl end_func // ��Ҫ����4 ���ַ����У�����Ų��£��򷵻ء�
	mov eax,func_table[eax*4] // ȡ���ܼ���Ӧ�ַ����С�
	xor ebx,ebx
	jmp put_queue // ���뻺������С�
end_func:
	ret

/*
* ���ܼ����͵�ɨ���룬F1 ��Ϊ��'esc [ [ A'�� F2 ��Ϊ��'esc [ [ B'�ȡ�
*/
func_table:
 DD 415b5b1bh,425b5b1bh,435b5b1bh,445b5b1bh
 DD 455b5b1bh,465b5b1bh,475b5b1bh,485b5b1bh
 DD 495b5b1bh,4a5b5b1bh,4b5b5b1bh,4c5b5b1bh

// ps:ֻ��KBD_US���ͨ��
// ɨ����-ASCII �ַ�ӳ�����
// ������config.h �ж���ļ�������(FINNISH��US��GERMEN��FRANCH)������Ӧ����ɨ����ӳ��
// ��ASCII �ַ���
#if defined(KBD_FINNISH)
// �����Ƿ�������̵�ɨ����ӳ�����
key_map:
 db 0,27 // ɨ����0x00,0x01 ��Ӧ��ASCII �룻
 db "1234567890+'" // ɨ����0x02,...0x0c,0x0d ��Ӧ��ASCII �룬�������ơ�
 db 127,9
 db "qwertyuiop}"
 db 0,13,0
 db "asdfghjkl|{"
 db 0,0
 db "'zxcvbnm,.-"
 db 0,'*',0,32 /* 36-39 */ /* ɨ����0x36-0x39 ��Ӧ��ASCII �� */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */ /* ɨ����0x4A-0x4E ��Ӧ��ASCII �� */
 db 0,0,0,0,0,0,0 /* 4F-55 */ /* ɨ����0x4F-0x55 ��Ӧ��ASCII �� */
 db '<'
 db 10 dup(0)

// shift ��ͬʱ����ʱ��ӳ�����
shift_map:
 db 0,27
 db '!','"',"#$%&/()=?`"
 db 127,9
 db "QWERTYUIOP]^"
 db 13,0
 db "ASDFGHJKL\["
 db 0,0
 db "*ZXCVBNM:_"
 db 0,'*',0,32 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '>'
 db 10 dup(0)

// alt ��ͬʱ����ʱ��ӳ�����
alt_map:
 db 0,0
 db 0,'@',0,'$',0,0,"{[]}",'\',0
 db 0,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db '~',13,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0,0,0 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db 0,0,0,0,0 /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '|'
 db 10 dup(0)

#elif defined(KBD_US)

// ��������ʽ���̵�ɨ����ӳ�����
key_map:
 db 0,27
 db "1234567890-="
 db 127,9
 db "qwertyuiop[]"
 db 13,0
 db "asdfghjkl;'"
 db '`',0
 db "\zxcvbnm,./"
 db 0,'*',0,32 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '<'
 db 10 dup(0)


shift_map:
 db 0,27
 db "!@#$%^&*()_+"
 db 127,9
 db "QWERTYUIOP{}"
 db 13,0
 db "ASDFGHJKL:",'"'
 db '~',0
 db "|ZXCVBNM<>?"
 db 0,'*',0,32 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '>'
 db 10 dup(0)

alt_map:
 db 0,0
 db 0,'@',0,'$',0,0,"{[]}","\",0
 db 0,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db '~',13,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0,0,0 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db 0,0,0,0,0 /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '|'
 db 10 dup(0)

#elif defined(KBD_GR)

// �����ǵ�����̵�ɨ����ӳ�����
key_map:
 db 0,27
 db "1234567890\'"
 db 127,9
 db "qwertzuiop@+"
 db 13,0
 db "asdfghjkl[]^"
 db 0,'#'
 db "yxcvbnm,.-"
 db 0,'*',0,32 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '<'
 db 10 dup(0)


shift_map:
 db 0,27
 db '!','"',"#$%&/()=?`"
 db 127,9
 db "QWERTZUIOP\*"
 db 13,0
 db "ASDFGHJKL{}~"
 db 0,''
 db "YXCVBNM:_"
 db 0,'*',0,32 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '>'
 db 10 dup(0)

alt_map:
 db 0,0
 db 0,'@',0,'$',0,0,"{[]}",'\',0
 db 0,0
 db '@',0,0,0,0,0,0,0,0,0,0
 db '~',13,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0,0,0 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db 0,0,0,0,0 /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '|'
 db 10 dup(0)


#elif defined(KBD_FR)

// �����Ƿ�����̵�ɨ����ӳ�����
key_map:
 db 0,27
 db "&{",'"',"'(-}_/@)="
 db 127,9
 db "azertyuiop^$"
 db 13,0
 db "qsdfghjklm|"
 db '`',0,42 /* coin sup gauche, don't know, [*|mu] */
 db "wxcvbn,:!"
 db 0,'*',0,32 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '<'
 db 10 dup(0)

shift_map:
 db 0,27
 db "1234567890]+"
 db 127,9
 db "AZERTYUIOP<>"
 db 13,0
 db "QSDFGHJKLM%"
 db '~',0,'#'
 db "WXCVBN?./\"
 db 0,'*',0,32 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db '-',0,0,0,'+' /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '>'
 db 10 dup(0)

alt_map:
 db 0,0
 db 0,"~#{[|`\^@]}"
 db 0,0
 db '@',0,0,0,0,0,0,0,0,0,0
 db '~',13,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0
 db 0,0,0,0,0,0,0,0,0,0,0
 db 0,0,0,0 /* 36-39 */
 db 16 dup(0) /* 3A-49 */ /* ɨ����0x3A-0x49 ��Ӧ��ASCII �� */
 db 0,0,0,0,0 /* 4A-4E */
 db 0,0,0,0,0,0,0 /* 4F-55 */
 db '|'
 db 10 dup(0)

#else
#error "KBD-type not defined"
#endif
/*
* do_self handles "normal" keys, ie keys that don't change meaning
* and which have just one character returns.
*/
/*
* do_self ���ڴ�������ͨ������Ҳ������û�б仯����ֻ��һ���ַ����صļ���
*/
do_self:
// 454-460 �����ڸ���ģʽ��־mode ѡ��alt_map��shift_map ��key_map ӳ���֮һ��
	lea ebx,alt_map // alt ��ͬʱ����ʱ��ӳ�����ַalt_map??ebx��
	test mode,20 /* alt-gr */ /* ��alt ��ͬʱ������? */
	jne l15 // �ǣ�����ǰ��ת�����1 ����
	lea ebx,shift_map // shift ��ͬʱ����ʱ��ӳ�����ַshift_map??ebx��
	test mode,03h // ��shift ��ͬʱ��������
	jne l15 // �У�����ǰ��ת�����1 ����
	lea ebx,key_map // ����ʹ����ͨӳ���key_map��
// ȡӳ����ж�Ӧɨ�����ASCII �ַ�����û�ж�Ӧ�ַ����򷵻�(תnone)��
l15:
	mov al,[ebx+eax] // ��ɨ������Ϊ����ֵ��ȡ��Ӧ��ASCII ��??al��
	or al,al // ��⿴�Ƿ��ж�Ӧ��ASCII �롣
	je none // ��û��(��Ӧ��ASCII ��=0)���򷵻ء�
// ��ctrl ���Ѱ��»�caps �������������ַ���'a'-'}'(0x61-0x7D)��Χ�ڣ�����ת�ɴ�д�ַ�
// (0x41-0x5D)��
	test mode,4ch /* ctrl or caps */ /* ���Ƽ��Ѱ��»�caps ����*/
	je l16 // û�У�����ǰ��ת���2 ����
	cmp al,'a' // ��al �е��ַ���'a'�Ƚϡ�
	jb l16 // ��al ֵ<'a'����ת���2 ����
	cmp al,'}' // ��al �е��ַ���'}'�Ƚϡ�
	ja l16 // ��al ֵ>'}'����ת���2 ����
	sub al,32 // ��al ת��Ϊ��д�ַ�(��0x20)��
// ��ctrl ���Ѱ��£������ַ���'`'--'_'(0x40-0x5F)֮��(�Ǵ�д�ַ�)������ת��Ϊ�����ַ�
// (0x00-0x1F)��
l16: 
	test mode,0ch /* ctrl */ /* ctrl ��ͬʱ��������*/
	je l17 // ��û����ת���3��
	cmp al,64 // ��al ��'@'(64)�ַ��Ƚ�(���ж��ַ�������Χ)��
	jb l17 // ��ֵ<'@'����ת���3��
	cmp al,64+32 // ��al ��'`'(96)�ַ��Ƚ�(���ж��ַ�������Χ)��
	jae l17 // ��ֵ>='`'����ת���3��
	sub al,64 // ����al ֵ��0x40��
// �����ַ�ת��Ϊ0x00-0x1f ֮��Ŀ����ַ���
// ����alt ��ͬʱ���£����ַ���λ7 ��λ��
l17: 
	test mode,10h /* left alt */ /* ��alt ��ͬʱ���£�*/
	je l18 // û�У���ת���4��
	or al,80h // �ַ���λ7 ��λ��
// ��al �е��ַ��������������С�
l18: 
	and eax,0ffh // ��eax �ĸ��ֺ�ah��
	xor ebx,ebx // ��ebx��
	call put_queue // ���ַ����뻺������С�
none: 
	ret

/*
* minus has a routine of it's own, as a 'E0h' before
* the scan code for minus means that the numeric keypad
* slash was pushed.
*/
/*
* ���������Լ��Ĵ����ӳ�����Ϊ�ڼ���ɨ����֮ǰ��0xe0
* ��ζ�Ű���������С�����ϵ�б�ܼ���
*/
minus: 
	cmp e0,1 // e0 ��־��λ����
	jne do_self // û�У������do_self �Լ��ŷ�������ͨ������
	mov eax,'/' // ������'/'�滻����'-'??al��
	xor ebx,ebx
	jmp put_queue // �����ַ����뻺������С�

/*
* This table decides which routine to call when a scan-code has been
* gotten. Most routines just call do_self, or none, depending if
* they are make or break.
*/
/* ������һ���ӳ����ַ��ת������ȡ��ɨ�����͸��ݴ˱�������Ӧ��ɨ���봦���ӳ���
* ��������õ��ӳ�����do_self��������none����������ǰ���(make)�����ͷż�(break)��
*/
key_table:
 DD none,   do_self,do_self,do_self /* 00-03 s0 esc 1 2 */
 DD do_self,do_self,do_self,do_self /* 04-07 3 4 5 6 */
 DD do_self,do_self,do_self,do_self /* 08-0B 7 8 9 0 */
 DD do_self,do_self,do_self,do_self /* 0C-0F + ' bs tab */
 DD do_self,do_self,do_self,do_self /* 10-13 q w e r */
 DD do_self,do_self,do_self,do_self /* 14-17 t y u i */
 DD do_self,do_self,do_self,do_self /* 18-1B o p } ^ */
 DD do_self,ctrl,   do_self,do_self /* 1C-1F enter ctrl a s */
 DD do_self,do_self,do_self,do_self /* 20-23 d f g h */
 DD do_self,do_self,do_self,do_self /* 24-27 j k l | */
 DD do_self,do_self,lshift, do_self /* 28-2B { para lshift , */
 DD do_self,do_self,do_self,do_self /* 2C-2F z x c v */
 DD do_self,do_self,do_self,do_self /* 30-33 b n m , */
 DD do_self,minus,  rshift, do_self /* 34-37 . - rshift * */
 DD alt,    do_self,caps,   func /* 38-3B alt sp caps f1 */
 DD func,   func,   func,   func /* 3C-3F f2 f3 f4 f5 */
 DD func,   func,   func,   func /* 40-43 f6 f7 f8 f9 */
 DD func,   num,    scroll, cursor /* 44-47 f10 num scr home */
 DD cursor, cursor, do_self,cursor /* 48-4B up pgup - left */
 DD cursor, cursor, do_self,cursor /* 4C-4F n5 right + end */
 DD cursor, cursor, cursor, cursor /* 50-53 dn pgdn ins del */
 DD none,   none,   do_self,func /* 54-57 sysreq ? < f11 */
 DD func,   none,   none,   none /* 58-5B f12 ? ? ? */
 DD none,   none,   none,   none /* 5C-5F ? ? ? ? */
 DD none,   none,   none,   none /* 60-63 ? ? ? ? */
 DD none,   none,   none,   none /* 64-67 ? ? ? ? */
 DD none,   none,   none,   none /* 68-6B ? ? ? ? */
 DD none,   none,   none,   none /* 6C-6F ? ? ? ? */
 DD none,   none,   none,   none /* 70-73 ? ? ? ? */
 DD none,   none,   none,   none /* 74-77 ? ? ? ? */
 DD none,   none,   none,   none /* 78-7B ? ? ? ? */
 DD none,   none,   none,   none /* 7C-7F ? ? ? ? */
 DD none,   none,   none,   none /* 80-83 ? br br br */
 DD none,   none,   none,   none /* 84-87 br br br br */
 DD none,   none,   none,   none /* 88-8B br br br br */
 DD none,   none,   none,   none /* 8C-8F br br br br */
 DD none,   none,   none,   none /* 90-93 br br br br */
 DD none,   none,   none,   none /* 94-97 br br br br */
 DD none,   none,   none,   none /* 98-9B br br br br */
 DD none,   unctrl, none,   none /* 9C-9F br unctrl br br */
 DD none,   none,   none,   none /* A0-A3 br br br br */
 DD none,   none,   none,   none /* A4-A7 br br br br */
 DD none,   none,   unlshift,none /* A8-AB br br unlshift br */
 DD none,   none,   none,   none /* AC-AF br br br br */
 DD none,   none,   none,   none /* B0-B3 br br br br */
 DD none,   none,   unrshift,none /* B4-B7 br br unrshift br */
 DD unalt,  none,   uncaps, none /* B8-BB unalt br uncaps br */
 DD none,none,none,none /* BC-BF br br br br */
 DD none,none,none,none /* C0-C3 br br br br */
 DD none,none,none,none /* C4-C7 br br br br */
 DD none,none,none,none /* C8-CB br br br br */
 DD none,none,none,none /* CC-CF br br br br */
 DD none,none,none,none /* D0-D3 br br br br */
 DD none,none,none,none /* D4-D7 br br br br */
 DD none,none,none,none /* D8-DB br ? ? ? */
 DD none,none,none,none /* DC-DF ? ? ? ? */
 DD none,none,none,none /* E0-E3 e0 e1 ? ? */
 DD none,none,none,none /* E4-E7 ? ? ? ? */
 DD none,none,none,none /* E8-EB ? ? ? ? */
 DD none,none,none,none /* EC-EF ? ? ? ? */
 DD none,none,none,none /* F0-F3 ? ? ? ? */
 DD none,none,none,none /* F4-F7 ? ? ? ? */
 DD none,none,none,none /* F8-FB ? ? ? ? */
 DD none,none,none,none /* FC-FF ? ? ? ? */

/*
* kb_wait waits for the keyboard controller buffer to empty.
* there is no timeout - if the buffer doesn't empty, we hang.
*/
/*
* �ӳ���kb_wait ���ڵȴ����̿���������ա������ڳ�ʱ���� - ���
* ������Զ���յĻ�������ͻ���Զ�ȴ�(����)��
*/
kb_wait:
	push eax
l19: 
	in al,64h // �����̿�����״̬��
	test al,02h // �������뻺�����Ƿ�Ϊ��(����0)��
	jne l19 // �����գ�����תѭ���ȴ���
	pop eax
	ret
/*
* This routine reboots the machine by asking the keyboard
* controller to pulse the reset-line low.
*/
/*
* ���ӳ���ͨ�����ü��̿���������λ����������壬ʹϵͳ��λ����(reboot)��
*/
reboot:
	call kb_wait // ���ȵȴ����̿��������뻺�����ա�
	mov word ptr ds:[472h],1234h /* don't do memory check */
	mov al,0fch /* pulse reset and A20 low */
	out 64h,al // ��ϵͳ��λ��A20 ����������塣
die: 
	jmp die // ������

end