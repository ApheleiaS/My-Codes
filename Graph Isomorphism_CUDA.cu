// Copyright (c) 2014 Godly T.Alias
//
// This is a free software; you can redistribute it and/or modify it
// under the terms of the GNU Lesser General Public License
// as published by the Free Software Foundation,
// either version 3 of the License, or (at your option) any later version.

#include<iostream>
#include<conio.h>
#include<fstream>
#include<direct.h>
using namespace std;

const int MAX_PERMUTATIONS=1000;

int n1,n2,perm;
struct mapping
{
int map_ver;
float state;
int classid; };

mapping *map_g;
float *g1,*g2;
int node,w_node;
int tmp_count;

void max_heapify(float *a,mapping *pos, int i, int n)
{
    int j, temps;
    float temp;
    temps = pos[i].map_ver;
    temp = a[temps];
    j = 2*i;
    while (j <= n)
    {
        if (j < n && a[pos[j+1].map_ver] > a[pos[j].map_ver])
            j = j+1;
        if (temp > a[pos[j].map_ver])
            break;
        else if (temp <= a[pos[j].map_ver])
        {
            pos[j/2].map_ver = pos[j].map_ver;
            j = 2*j;
        }
    }
    pos[j/2].map_ver = temps;
    return;
}
void heapsort(float *a,mapping *pos, int end)
{
    int i, temps;
    float temp;
    for (i = end; i >= 2; i--)
    {
        temps = pos[i].map_ver;
        pos[i].map_ver = pos[1].map_ver;
        pos[1].map_ver = temps;
        max_heapify(a,pos, 1, i - 1);
    }
}
void build_maxheap(float *a,mapping *pos, int end)
{
    int i;
    for(i = end/2; i >= 1; i--)
    {
        max_heapify(a,pos, i, end);
    }
}

bool adj_mat_map(float *a1, float *a2)
{
int i,j;
for(i=0;i<node;i++)
 for(j=0;j<node;j++)
  if(a1[map_g[i].map_ver*node+map_g[j].map_ver]!=a2[map_g[1*node+i].map_ver*node+map_g[1*node+j].map_ver])
   return false;
return true;
}


int isotest(int p1_init_node,int p2_init_node,float *a1,float *a2)
{
    char filename[40];
    sprintf(filename,"../graphiso/map_0_%d",p1_init_node);
    FILE *read1 = fopen(filename,"r");
    sprintf(filename,"../graphiso/map_1_%d",p2_init_node);
    FILE *read2 = fopen(filename,"r");
while(!feof(read1)){
for(int i=0;i<node;i++)
 fscanf(read1,"%d",&map_g[i].map_ver);

while(!feof(read2)){
for(int j=0;j<node;j++)
 fscanf(read2,"%d",&map_g[1*node+j].map_ver);

  if(adj_mat_map(a1,a2))
 { fclose(read1);
   fclose(read2);
   return 2; } }
      
 fseek(read2,0,SEEK_SET);
    }
fclose(read1);
fclose(read2);
 return 0;
}

float *row_mat,*row_mat_copy;
//returns the initial state distribution vector
void istate_dibn_vec(float* init_state, int i,int n)
{
for(int j=0;j<n;j++)
 if(j==i)
  init_state[j]=1.0;
 else
  init_state[j]=0.0;
}

//computes the product of matrices m1 & m2 and write the result in res matrix
void matrix_prod(float *res,float *m1,int c1,float *m2,int r2,int c2)
{
float y,t,c;
if(c1==r2){
 for(int j=0;j<c2;j++){
 res[j]=0;
 c=0.0;
  for(int k=0;k<c1;k++){
//kahan summation to avoid precision lose
  y=(m1[k]*m2[k*node+j])-c;
  t=res[j]+y;
  c = (t-res[j])-y;
  res[j]=t;}
 }
}}

//swaps the given parameters
void swap(mapping *a,mapping *b)
{
 mapping temp;
 temp=*a;
 *a=*b;
 *b=temp;     
}

//output all the possible mappings when 2 column vectors of 
//probability propogation matrix becomes equal
void permute(int start,int end,FILE *file,int graph_id,bool flag)
{
// if(perm<MAX_PERMUTATIONS){
 int t_start=0,t_end=0;
 if(start==end && flag)
 {
 perm++;
 for(int i=0;i<node;i++)
  fprintf(file,"%d ",map_g[graph_id*node+i].map_ver);
 fprintf(file,"\n");
 }
 else
 {
 for(int i=0;i<=(end-start);i++)
  {
   swap(&map_g[graph_id*node+start],&map_g[graph_id*node+start+i]);
   if((start==0 || start>0 && map_g[graph_id*node+start].classid!=map_g[graph_id*node+start-1].classid || i!=0)&& end<(node-1))
   {
   for(int j=end+1;j<(node-1);j++)
    if(map_g[graph_id*node+j].classid==map_g[graph_id*node+j+1].classid)
     { t_start=j; break; }
   if(t_start>0)
   for(int j=t_start+1;j<node-1;j++)
    if(map_g[graph_id*node+j].classid!=map_g[graph_id*node+j+1].classid) //no need to check for last element in the row as it will always be different
     { t_end = j; break; }
   if(t_start!=t_end){
     permute(t_start,t_end,file,graph_id,true);
     flag=false;}}
   permute(start+1,end,file,graph_id,flag);
   flag=true;
   swap(&map_g[graph_id*node+start+i],&map_g[graph_id*node+start]);
   }
 }
}//}

//calculates the probability propogation matrix for the initial state initstate
void prob_prop_matrix(int graph_id, float *g, int n, int initstate)
{
char file_name[40];
bool flag=true;
int start,end,j,temp,classptr;
int ptr = graph_id*node;
float temps;
sprintf(file_name,"../graphiso/map_%d_%d",graph_id,initstate);
FILE *write = fopen(file_name,"w");
//row_mat holds the value of each state distribution vector
row_mat = new float[n];
row_mat_copy = new float[n];
//writes the initial state vector to the row_mat
istate_dibn_vec(row_mat,initstate,n);
classptr=1;
for(int i=0;flag && i<((2*n)-1);i++)
{
for(j=0;j<n;j++)
 row_mat_copy[j]=row_mat[j];
        j=1;
        //this loop gives different class id to vertices with same class id but different state
        while(j<n)
        {
        if(map_g[ptr+j].classid==map_g[ptr+j-1].classid)
        {
         if(map_g[ptr+j].state!=map_g[ptr+j-1].state)
          {
            temp=map_g[ptr+j].classid;
          while(j<n && map_g[ptr+j].classid==temp){
            temps=map_g[ptr+j].state;
             while(j<n && map_g[ptr+j].state==temps && map_g[ptr+j].classid==temp){
              map_g[ptr+j].classid=classptr;
              j++;
              }
              classptr++;
              }  
             }  
          else j++;
             }
         else j++;
        }
               
        start=0;
        j=0;
        flag=false;
        while(j<n)
        {
        end=start+1;
        j++;
        while(j<n && map_g[ptr+end].classid==map_g[ptr+start].classid)
        {
          j++; end++;               
         }
        if(start<end-1){
           build_maxheap(row_mat,&map_g[ptr-1+start],end-start);
           heapsort(row_mat,&map_g[ptr-1+start],end-start); //subtracting 1 from array subscript for the padding for heap sort
 
        flag=true;
        }                        
        start=end;
        }
       
//writing state distribution vector to probability propogation matrix
for(j=0;j<n;j++)
 map_g[ptr+j].state=row_mat[map_g[ptr+j].map_ver];
 
//calculating the state distribution vector for string of next length
matrix_prod(row_mat,row_mat_copy,n,g,n,n);
}

delete [] row_mat;
delete [] row_mat_copy;
start=0;
while(start<n-1){
 if(map_g[ptr+start].classid==map_g[ptr+start+1].classid)
  break;
 start++; }
end=start+1;
while(end<n-1){
 if(map_g[ptr+end].classid!=map_g[ptr+end+1].classid)
  break;
 end++; }
 perm=0;
if(start<end && end<n)
 permute(start,end,write,graph_id,true);
else
{
for(int i=0;i<node;i++)
  fprintf(write,"%d ",map_g[ptr+i].map_ver);
 fprintf(write,"\n");   
}
fclose(write);
}
//returns the degree of a vertix
int degree(float *m,int row,int n)
{
int deg=0;
int base_ptr=row*node;
for(int i=0;i<n;i++){
deg+=(int)m[base_ptr+i];}
return deg;
}

//computing the probability distribution matrices
void prob_dibn(float *m,int n)
{
int deg;
for(int i=0;i<n;i++){
 deg = degree(m,i,n);
 for(int j=0;j<n;j++)
 {
 m[i*node+j]/=deg;
 }
}
}

void get_graphs()
{
     int mode=0;
     char ch=' ';
     FILE *f = fopen("g1.txt","r");
      n1=0;n2=0;
         //checking the no: of nodes in the graph 1
		 while(ch!='\n')
         {
         ch = fgetc(f);
          if(ch>=48 && ch<=57 && mode==0)
           {
             mode=1;
               n1++;
            }
             else if(ch<48 || ch>57)
              mode=0;
          }
          node=n1;
          //initializing graph 1 and inputing values
         g1 = new float[n1*n1];
         fseek(f,0,SEEK_SET);
         for(int i=0;i<n1;i++)
         for(int j=0;j<n1;j++)
         fscanf(f,"%f ",&g1[i*n1+j]);
         fclose(f);
         ch=' ';
mode=0;
f = fopen("g2.txt","r");
//reading the adjacent matrix of Graph 2
//first checking the no: of elements in a row
while(ch!='\n')
{
ch = fgetc(f);
 if(ch>=48 && ch<=57 && mode==0)
 {
  mode=1;
  n2++;
 }
 else if(ch==' ')
  mode=0;
}
         g2 = new float[n2*n2];
         fseek(f,0,SEEK_SET);
         for(int i=0;i<n2;i++)
         for(int j=0;j<n2;j++)
         fscanf(f,"%f ",&g2[i*n2+j]);
         
         fclose(f); 
         
         //computing probability distribution matrices of both graphs
prob_dibn(g1,n1); //g1 is converted to the probability distribution matrix of graph 1
prob_dibn(g2,n2); //g2 is converted to the probability distribution matrix of graph 2          
     }

int main()
{
    #if defined(_WIN32)
    _mkdir("../graphiso");
    _mkdir("../results");
    #else
    mkdir("../graphiso", 0777);
    mkdir("../results",0777);
    #endif

FILE *result;

int i,j,mode,deg=0,pi,pj,iso;
char ch,filename[40];
ch=' ';
get_graphs();

map_g = new mapping[2*n1];


FILE *read1,*read2;

if(n1==n2) //if number of vertices of both graphs are not equal then not isomorphic
{
 //dynamically allocating array for probability distribution matrix
 for(pi=0;(pi<n1)&&(iso!=2);pi++)
 {
        for(int i=0;i<n1;i++)
        {
        map_g[i].map_ver=i;
        map_g[i].state=-1.0;
        map_g[i].classid=0;
        }
  sprintf(filename,"../graphiso/map_%d_%d",0,pi);  
  read1=fopen(filename,"r");
  if(!read1)
   prob_prop_matrix(0,g1,n1,pi);
   else
  fclose(read1);
 // cout<<"\ndone\n";
  for(pj=0;(pj<n2)&&(iso!=2);pj++)
  {
   for(int i=0;i<n1;i++)
        {
        map_g[n1+i].map_ver=i;
        map_g[n1+i].state=-1.0;
        map_g[n1+i].classid=0;
        }
   sprintf(filename,"../graphiso/map_%d_%d",1,pj);
   read2=fopen(filename,"r");
   if(!read2)
    prob_prop_matrix(1,g2,n2,pj);
    else
   fclose(read2);
   iso = isotest(pi,pj,g1,g2);
    if(iso==2)
{
sprintf(filename,"../results/res_%d_%d",pi,pj);
result=fopen(filename,"w");
fprintf(result,"ISOMORPHIC MAPPING\n");
for(int l=0;l<n1;l++)
fprintf(result,"%d -> %d\n",map_g[l].map_ver,map_g[n1+l].map_ver);
fprintf(result,"\n----------------\n");
fclose(result);
}
  }
  
  }
}
else
cout<<"NOT ISOMORPHIC\n";


//deleting memory allocated for arrays
delete [] g1;
delete [] g2;
delete [] map_g;
getch();
return 0;
}
