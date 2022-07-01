#define SOURCE ((volatile int*)0x1000)
#define TARGET ((volatile int*)0x1004)
#define UART_TX *((volatile unsigned char*)0x40600004)

#define INCREASEMENT 0
#define KEEP 1
#define DOUBLE 2
#define SPECIAL 3

void func0(int a){
	for(int i = 0; i < a; i++){
		TARGET[i] = i;
	}
}

void func1(int a){
	for(int i = 0; i < a; i++){
	    func0(2);
		TARGET[i] = 0;
	}
}

void func2(int a){
	int u = 1;
	for(int i = 0; i < a; i++){
		func1(2);
		TARGET[i] = u;
		u = u >> 1;
	}
}

void func3(int a){
	int u = 0;
	for(int i = 0; i < a; i++){
		func2(2);
		TARGET[i] = 0;
		u = u + i;
	}
}

int main(){
	func3(3);
}