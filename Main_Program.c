#include <16F877A.h>
#device ADC=16
#FUSES NOWDT                    //No Watch Dog Timer
#FUSES NOBROWNOUT               //No brownout reset
#FUSES NOLVP                    //No low voltage prgming, B3(PIC16) or B5(PIC18) used for I/O
#use delay(clock=20000000)
#use rs232(baud=9600,xmit=PIN_C6,rcv=PIN_C7)
#define LCD_RS_PIN      PIN_D1
#define LCD_RW_PIN      PIN_D2
#define LCD_ENABLE_PIN  PIN_D3
#define LCD_DATA4       PIN_D4
#define LCD_DATA5       PIN_D5
#define LCD_DATA6       PIN_D6
#define LCD_DATA7       PIN_D7
#include <lcd.c>
#include <stdlib.h>
int uartFlg;
int state;     // Define state and uart flag     
char sp[11];

#INT_RDA
void uart(){
    gets(sp);    
    if(sp[0]=='#')
    {
      sp[0]='0';
      state=1;
    }
    uartFlg=1;
}
void main()
{
   set_tris_d(0x00);     
   lcd_init();
   lcd_putc('\f');
   lcd_gotoxy(1,1);
   lcd_putc("Ready!");
   enable_interrupts(global);    //Setting up interrupts
   enable_interrupts(int_rda);
      
   float kp=100,ki=20,kd=1,tsamp=0.01;   //Define PID parameters
   float setpoint=0,volt=0,in_speed=0;
   float integral=0,last_error=0,error=0,derivative=0;
   char voltage[11];  
   int16 count=0,duration=10;  // Different from 0 to avoid auto reset
   
   while(TRUE)
   {        
      if((uartFlg==1)&&(state==0))  //Receiving simulation time from GUI
      {
         duration=atoi(sp);
         duration*=100; //Working duration (1/tsamp*second)             
         uartFlg=0;
         state=1;      
      }
      if((uartFlg==1)&&(state==1))  //Receiving set point value from GUI
      {
         setpoint=atof(sp);
         uartFlg=0;
         state=2;      
      }
      if((uartFlg==1)&&(state==2))  //Receiving feedback speed 
      {
         in_speed=atof(sp);           
         count+=1;
         uartFlg=2;        
         error=setpoint-in_speed;   //PID calculation
         derivative=(error-last_error)/tsamp;
         integral+=error*tsamp;
         last_error=error;
         volt=kp*error+ki*integral+kd*derivative;  
         if (volt>1023) volt=1023;    //PID upper and lower limits
         else (volt<-1023) volt=-1023;
      }
      if((uartFlg==2)&&(state==2))  //Transmitting PID value to adjust the system
      {   
         sprintf(voltage, "%.3f", volt);         
         lcd_putc('\f');
         lcd_gotoxy(1,1);
         printf(lcd_putc,"PID:%.3f",volt);   //PID value output 
         puts(voltage);
         uartFlg=0;
      }  
      if(count==duration) //Reset variables after simulation done
      {
         lcd_putc('\f');
         lcd_gotoxy(1,1);
         lcd_putc("Ready!");
         setpoint=0;
         volt=0;
         in_speed=0;
         integral=0;
         last_error=0;
         error=0;
         derivative=0;
         state=0;
         count=0;
      }
   
   }
}
