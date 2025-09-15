procedure menu(var f: text; m: menuptr);

var win: winptr;  { pointer to windows context }
    b:   boolean; { function result }

begin

0x00425f56 <menu+0>:    enter  $0xc,$0x2
0x00425f5a <menu+4>:    pushf
0x00425f5b <menu+5>:    push   %edi
0x00425f5c <menu+6>:    push   %esi
0x00425f5d <menu+7>:    push   %edx
0x00425f5e <menu+8>:    push   %ecx
0x00425f5f <menu+9>:    push   %ebx
0x00425f60 <menu+10>:   push   %eax
0x00425f61 <menu+11>:   lea    0x1c(%esp,1),%edi
0x00425f65 <menu+15>:   xor    %eax,%eax
0x00425f67 <menu+17>:   mov    $0x3,%ecx
0x00425f6c <menu+22>:   repnz stos %eax,%es:(%edi)
   win := txt2win(f); { get windows context }
0x00425f6e <menu+24>:   mov    0xffffffd0(%ebp),%eax
0x00425f74 <menu+30>:   call   0x4136a8 <gralib_txt2win>
0x00425f79 <menu+35>:   mov    %eax,0xffffffec(%ebp)
   with win^ do begin { in windows context }
0x00425f7f <menu+41>:   mov    %eax,0xfffffff1(%ebp) ! place win^ with var
      if menhan <> 0 then begin { distroy previous menu }
0x00425f85 <menu+47>:   mov    0xfffffff1(%ebp),%eax
0x00425f8b <menu+53>:   mov    0x61a(%eax),%eax
0x00425f91 <menu+59>:   cmp    $0x0,%eax
0x00425f94 <menu+62>:   je     0x425fbe <menu+104>
         b := sc_destroymenu(menhan); { destroy it }
0x00425f9a <menu+68>:   mov    0xfffffff1(%ebp),%eax
0x00425fa0 <menu+74>:   lea    0x61a(%eax),%eax
0x00425fa6 <menu+80>:   call   0x402d70 <sc_destroymenu>
0x00425fab <menu+85>:   mov    %al,0xfffffff0(%ebp)
         if not b then winerr { process windows error }
0x00425fb1 <menu+91>:   or     %eax,%eax
0x00425fb3 <menu+93>:   jne    0x425fbe <menu+104>
0x00425fb9 <menu+99>:   call   0x412dfc <gralib_winerr>
      end;
      if m <> nil then begin { there is a new menu to activate }
0x00425fbe <menu+104>:  mov    0xffffffd4(%ebp),%eax
0x00425fc4 <menu+110>:  cmp    $0x0,%eax
0x00425fc7 <menu+113>:  je     0x42604b <menu+245>
         menhan := sc_createmenu; { create new menu }
0x00425fcd <menu+119>:  call   0x402d51 <sc_createmenu>
0x00425fd2 <menu+124>:  mov    0xfffffff1(%ebp),%ebx    ! get win^
0x00425fd8 <menu+130>:  mov    %eax,0x61a(%ebx)         ! place menhan in offset
         if menhan = 0 then winerr; { process windows error }
0x00425fde <menu+136>:  cmp    $0x0,%eax			    ! check =0
0x00425fe1 <menu+139>:  jne    0x425fec <menu+150>      ! skip if not
0x00425fe7 <menu+145>:  call   0x412dfc <gralib_winerr>	! error
         while m <> nil do begin { add menu item }
0x00425fec <menu+150>:  mov    0xffffffd4(%ebp),%eax	! check m = 0
0x00425ff2 <menu+156>:  cmp    $0x0,%eax
0x00425ff5 <menu+159>:  je     0x42604b <menu+245>		! yes, skip
            b := sc_appendmenu(menhan, sc_mf_string, m^.id, m^.face^);
0x00425ffb <menu+165>:  add    $0x10,%eax				! get m^.face
0x00425ffe <menu+168>:  mov    0x4(%eax),%ebx			! get length to ebx
0x00426001 <menu+171>:  mov    (%eax),%eax				! get address to eax
0x00426003 <menu+173>:  mov    0xfffffff1(%ebp),%ecx	! get win^
0x00426009 <menu+179>:  lea    0x61a(%ecx),%ecx			! get menhan to ecx
0x0042600f <menu+185>:  mov    $0x0,%edx				! get 0 to edx
0x00426015 <menu+191>:  mov    0xffffffd4(%ebp),%esi	! get m
0x0042601b <menu+197>:  add    $0xc,%esi				! get m^.id
0x0042601e <menu+200>:  mov    (%esi),%esi
0x00426020 <menu+202>:  call   0x402d9b <sc_appendmenu>
0x00426025 <menu+207>:  mov    %al,0xfffffff0(%ebp)
            if not b then winerr; { process windows error }
0x0042602b <menu+213>:  or     %eax,%eax
0x0042602d <menu+215>:  jne    0x426038 <menu+226>
0x00426033 <menu+221>:  call   0x412dfc <gralib_winerr>
            m := m^.next { next menu entry }
0x00426038 <menu+226>:  mov    0xffffffd4(%ebp),%eax
0x0042603e <menu+232>:  mov    (%eax),%eax
0x00426040 <menu+234>:  mov    %eax,0xffffffd4(%ebp)
0x00426046 <menu+240>:  jmp    0x425fec <menu+150>
      b := sc_drawmenubar(menhan); { display menu }
0x0042604b <menu+245>:  mov    0xfffffff1(%ebp),%eax
0x00426051 <menu+251>:  lea    0x61a(%eax),%eax
0x00426057 <menu+257>:  call   0x402de1 <sc_drawmenubar>
0x0042605c <menu+262>:  mov    %al,0xfffffff0(%ebp)
      if not b then winerr { process windows error }
0x00426062 <menu+268>:  or     %eax,%eax
0x00426064 <menu+270>:  jne    0x42606f <menu+281>
0x0042606a <menu+276>:  call   0x412dfc <gralib_winerr>

   end

end;
0x0042606f <menu+281>:  pop    %eax
0x00426070 <menu+282>:  pop    %ebx
0x00426071 <menu+283>:  pop    %ecx
0x00426072 <menu+284>:  pop    %edx
0x00426073 <menu+285>:  pop    %esi
0x00426074 <menu+286>:  pop    %edi
0x00426075 <menu+287>:  popf
0x00426076 <menu+288>:  leave
0x00426077 <menu+289>:  ret