#include<iostream>
using namespace std;
//int twoNumAdd(const int &a,int b=1);
float twoNumAdd(float a,float b);
int twoNumAdd(int &a,int b);
int main(int argc,char** argv){
    int d=1;
int c=twoNumAdd(d,1);
float e=twoNumAdd(1.1f,2.1f);
cout<<c<<endl;
cout<<d<<endl;
    // for(int i=1;i<100;i++){
    //     if(i%3==0){
    //     cout<<i<<" ";
    //     }
    // }
    // cout<<"argc="<<argc<<"\t"<<"argv[1]="<<argv[1];
    // cout<<endl;

    return 0;
}
//  int twoNumAdd(const int &a,int b=1){
//      }
 int twoNumAdd(int &a,int b=1){
     b++;
    //  a++;
    return a+b;
}

 float twoNumAdd(float a,float b){
    //  a++;
    return a+b;
}