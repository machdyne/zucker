/*
 * Lone Lisp (LIX edition)
 * Copyright (c) 2021 Lone Dynamics Corporation. All rights reserved.
 *
 * Redistribution and use in source, binary or physical forms, with or without
 * modification, is permitted provided that the following condition is met:
 *
 * * Redistributions of source code must retain the above copyright notice,
 * this list of conditions and the following disclaimer.
 *
 * THIS HARDWARE, SOFTWARE, DATA AND/OR DOCUMENTATION ("THE ASSETS") IS
 * PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
 * INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 * OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY
 * ARISING FROM, OUT OF OR IN CONNECTION WITH THE ASSETS OR THE USE OR OTHER
 * DEALINGS IN THE ASSETS. USE AT YOUR OWN RISK.
 *
 * This is an unfinished broken "toy lisp" adapted for LIX OS on Zucker SOC,
 * feel free to fix/improve it. It can also be built on Linux:
 *
 * $ gcc -o ll ll.c -lm && ./ll
 * ll> (load ll_stdlib.l)
 *
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <stdbool.h>
#include <string.h>
#include <ctype.h>
#include <math.h>
#include <unistd.h>
#include <time.h>

#ifdef LIX
#include "include/fs.h"
#include "../common/zucker.h"
#include "ll_stdlib.h"
#endif

#define TRUE v_atom_true
#define FALSE v_list_nil
#define NIL v_atom_nil

#define MAX_STR_LEN 1024

#define CAR(x) (l_value *)(x)->car
#define CDR(x) (l_value *)(x)->cdr
#define CONS(x, y) v_list(x, y)

#define PUSH(x, y) (x = CONS(y, x))
#define POP(y) (y = CDR(y))

typedef struct l_value {

	enum { ATOM, NUM, STR, LIST, FUN, LAMBDA } type;

	union {
		void *(*fun)(void *, void *);
		char *str;
		double val;
	};

	void *car;
	void *cdr;
	void *env;
	bool marked;

} l_value;

typedef struct l_env {

	void *first;
	void *parent;

} l_env;

typedef struct l_env_val {

	char *key;
	l_value *val;
	void *next;

} l_env_val;

typedef struct l_obj {

	int count;
	void *first;

} l_obj;

typedef struct l_obj_val {

	l_value *val;
	void *next;

} l_obj_val;

typedef struct l_tok {

	enum { TATOM, TNUM, TLPAR, TRPAR, TQUOTE, TSTR, TCOMMENT } type;
	char *str;
	char *next;

} l_tok;

typedef enum { L_PANIC, L_ERROR, L_INFO } l_log_level;
typedef enum { L_ADD, L_SUB, L_MUL, L_DIV, L_MOD } l_arith_ops;

l_value *v_atom_true;
l_value *v_list_nil;
l_value *v_atom_nil;
l_value *v_atom_lambda;
l_value *v_atom_quote;
l_value *v_atom_while;

// PROTOTYPES

void l_init(void);
void l_init_lix(bool stdlib);

void l_log(l_log_level level, const char *fmt, ...);
void l_dump(l_value *x);
void l_dump_nl(l_value *x);
void l_dump_inner(l_value *x, int depth, bool nl);

char *l_dump_lisp(l_value *x);
void l_dump_lisp_inner(l_value *x);

bool l_eq(l_value *x, l_value *y);

l_obj *l_objs;
void l_obj_init(void);
l_value *l_obj_alloc(void);
void l_obj_free(l_obj_val *mv, l_obj_val *pmv);

l_value *l_gc_stack;
void l_gc(l_env *e);
void l_gc_mark_env(l_env *e);
void l_gc_mark(l_value *v);
void l_gc_sweep(void);

l_env *l_env_root;
l_env *l_env_new(void);
l_env *l_env_std(void);

void l_env_set(l_env *e, char *key, l_value *x);
void l_env_set_local(l_env *e, char *key, l_value *x);
l_value *l_env_find(l_env *e, char *key);
l_env_val *l_env_find_ptr(l_env *e, char *key);
void l_env_dump(l_env *e);

l_tok *l_token(char *s);

void l_ep(char *buf);
void l_repl_simple(l_env *env);

void l_load(char *filename, l_env *e);

l_value *l_read(const char *s);
l_value *l_read_list(void);
l_value *l_eval(l_value *x, l_env *e);
l_value *l_apply(l_value *lambda, l_value *args, l_env *e);

l_value *v_atom(char *s);
l_value *v_num(double n);
l_value *v_num_from_str(char *s);
l_value *v_str(char *s);
l_value *v_list(l_value *car, l_value *cdr);
l_value *v_fun(void *fun);
l_value *v_lambda(l_value *lambda, l_env *e);

l_value *op_car(l_value *args, l_env *e);
l_value *op_cdr(l_value *args, l_env *e);
l_value *op_quote(l_value *args, l_env *e);
l_value *op_atom(l_value *args, l_env *e);
l_value *op_num(l_value *args, l_env *e);
l_value *op_str(l_value *args, l_env *e);
l_value *op_pair(l_value *args, l_env *e);
l_value *op_eq(l_value *args, l_env *e);
l_value *op_neq(l_value *args, l_env *e);
l_value *op_lt(l_value *args, l_env *e);
l_value *op_lte(l_value *args, l_env *e);
l_value *op_gt(l_value *args, l_env *e);
l_value *op_gte(l_value *args, l_env *e);
l_value *op_cons(l_value *args, l_env *e);
l_value *op_cond(l_value *args, l_env *e);
l_value *op_if(l_value *args, l_env *e);
l_value *op_let(l_value *args, l_env *e);
l_value *op_set(l_value *args, l_env *e);
l_value *op_defun(l_value *args, l_env *e);
l_value *op_define(l_value *args, l_env *e);
l_value *op_begin(l_value *args, l_env *e);
l_value *op_list(l_value *args, l_env *e);
l_value *op_dump(l_value *args, l_env *e);
l_value *op_load(l_value *args, l_env *e);
l_value *op_pp(l_value *args, l_env *e);
l_value *op_pn(l_value *args, l_env *e);
l_value *op_read(l_value *args, l_env *e);
l_value *op_eval(l_value *args, l_env *e);
l_value *op_gc(l_value *args, l_env *e);
l_value *op_exit(l_value *args, l_env *e);

l_value *op_str_to_list(l_value *args, l_env *e);
l_value *op_list_to_str(l_value *args, l_env *e);
l_value *op_num_to_str(l_value *args, l_env *e);
l_value *op_file_to_str(l_value *args, l_env *e);

l_value *op_arith(l_value *args, l_env *e, l_arith_ops op);
l_value *op_add(l_value *args, l_env *e);
l_value *op_sub(l_value *args, l_env *e);
l_value *op_mul(l_value *args, l_env *e);
l_value *op_div(l_value *args, l_env *e);
l_value *op_mod(l_value *args, l_env *e);
l_value *op_time(l_value *args, l_env *e);

// UTILS

void l_log(l_log_level level, const char *fmt, ...) {
	va_list args;
	va_start(args, fmt);
	if (level == L_INFO) fprintf(stderr, "[info] ");
	else if (level == L_ERROR) fprintf(stderr, "[error] ");
	else if (level == L_PANIC) fprintf(stderr, "[panic] ");
	vfprintf(stderr, fmt, args);
	fprintf(stderr, "\n");
	va_end(args);
	if (level == L_PANIC) exit(EXIT_FAILURE);
}

void l_dump(l_value *x) {
	l_dump_inner(x, 0, false);
}

void l_dump_nl(l_value *x) {
	l_dump_inner(x, 0, true);
}

void l_dump_inner(l_value *x, int depth, bool nl) {
	if (x == NULL) { printf("[NULL]\n"); return; }
	switch (x->type) {
		case ATOM: printf("[atom:%s] ", x->str); break;
		case NUM: printf("[num:%f] ", x->val); break;
		case STR: printf("[str:%s] ", x->str); break;
		case FUN: printf("[fun]"); break;
		case LAMBDA: printf("[lambda]"); break;
		case LIST:
			printf("[list: ");
			l_value *ptr = x;
			while (1) {
				if (l_eq(ptr->car, NIL)) break;
				l_dump_inner(ptr->car, depth + 1, nl);
				if (l_eq(ptr->cdr, NIL)) break;
				ptr = ptr->cdr;
			}
			printf("] ");
			break;
	}
	if (nl && depth == 0) printf("\n");
}

// SERIALIZATION

char *l_dump_lisp_ptr;

char *l_dump_lisp(l_value *x) {
	char *str = (char *)calloc(1, MAX_STR_LEN);
	l_dump_lisp_ptr = str;
	l_dump_lisp_inner(x);
	return str;
}

void l_dump_lisp_inner(l_value *x) {

	char buf[MAX_STR_LEN];

	if (x == NULL) {
		sprintf(l_dump_lisp_ptr, "null");
		l_dump_lisp_ptr += 4;
		return;
	}

	switch (x->type) {
		case ATOM:
			strncpy(l_dump_lisp_ptr, x->str, strlen(x->str));
			l_dump_lisp_ptr += strlen(x->str);
			break;
		case NUM:
			sprintf(buf, "%f", x->val);
			strncpy(l_dump_lisp_ptr, buf, strlen(buf));
			l_dump_lisp_ptr += strlen(buf);
			break;
		case STR:
			sprintf(l_dump_lisp_ptr, "\"%s\"", x->str);
			l_dump_lisp_ptr += strlen(x->str) + 2;
			break;
		case LAMBDA:
		case LIST:
			sprintf(l_dump_lisp_ptr, "(");
			l_dump_lisp_ptr += 1;
			l_value *ptr = x;
			while (1) {
				if (l_eq(ptr->car, NIL)) break;
				l_dump_lisp_inner(ptr->car);
				sprintf(l_dump_lisp_ptr, " ");
				l_dump_lisp_ptr += 1;
				if (l_eq(ptr->cdr, NIL)) break;
				ptr = ptr->cdr;
			}
			if (*(l_dump_lisp_ptr - 1) == ' ') l_dump_lisp_ptr -= 1;
			sprintf(l_dump_lisp_ptr, ")");
			l_dump_lisp_ptr += 1;
			break;
		default:
			break;
	}
}

// EQUALITY

bool l_eq(l_value *x, l_value *y) {

	if (x->type == NUM && y->type == NUM) {
		if (x->val == y->val) 
			return true; else return false;
	}

	if (x->type == LIST && y->type == ATOM) {
		if (l_eq(x->car, NIL) && l_eq(y, NIL))
			return true; else return false;
	}

	if (x->type == ATOM && y->type == LIST) {
		if (l_eq(x, NIL) && l_eq(y->car, NIL))
			return true; else return false;
	}

	if (x->type != y->type) return false; 

	if (x->type == LIST) {
		if (l_eq(x->car, NIL) && l_eq(y->car, NIL))
			return true; else return false;
	}

	if (x->type == ATOM || x->type == STR) {
		int s1 = strlen(x->str);
		int s2 = strlen(y->str);
		if (s1 != s2) return false;
		if (strncmp(x->str, y->str, s1) == 0) return true; else return false;
	}

	return false;

}

// ENVIRONMENT

l_env *l_env_new(void) {
	l_env *env = (l_env *)malloc(sizeof(l_env));
	env->first = NULL;
	env->parent = NULL;
	return env;
};

void l_env_set_local(l_env *e, char *key, l_value *x) {
	void *parent = e->parent;
	e->parent = NULL;
	l_env_set(e, key, x);
	e->parent = parent;
}

void l_env_set(l_env *e, char *key, l_value *x) {

	PUSH(l_gc_stack, v_atom(key));

	l_env_val *ptr = l_env_find_ptr(e, key);

	if (ptr != NULL) {
		ptr->val = x;
		return;
	}

	l_env_val *ev = (l_env_val *)malloc(sizeof(l_env_val));
	ev->key = key;
	ev->val = x;
	ev->next = NULL;

	if (!e->first) {
		e->first = ev;
	} else {
		ptr = e->first;
		while (1) {
			if (ptr == NULL) break; 
			if (ptr->next == NULL) break;
			ptr = ptr->next;
		}
		ptr->next = ev;
	}

}

l_value *l_env_find(l_env *e, char *key) {

	l_env_val *ptr = l_env_find_ptr(e, key);

	if (ptr == NULL || ptr->val == NULL)
		return NIL;
	else
		return ptr->val;

}

l_env_val *l_env_find_ptr(l_env *e, char *key) {

	l_env_val *ptr = e->first;

	while (1) {

		if (ptr == NULL) break;

		if (strlen(key) == strlen(ptr->key) &&
			strncmp(key, ptr->key, strlen(key)) == 0)
		{
			return ptr;
		}

		if (ptr->next == NULL) break;
		ptr = ptr->next;

	}

	if (e->parent != NULL)
		return l_env_find_ptr(e->parent, key);

	return NULL;

}

void l_env_dump(l_env *e) {

	l_env_val *ptr = e->first;

	printf("ENV:\n");

	while (1) {

		if (ptr == NULL) break;

		l_value *v = ptr->val;

		printf(" %s ", ptr->key); l_dump_nl(v);

		if (ptr->next == NULL) break;
		ptr = ptr->next;

	}

	if (e->parent != NULL) l_env_dump(e->parent);

}

// BROKEN GARBAGE COLLECTION

void l_gc(l_env *e) {
	l_gc_mark(l_gc_stack);
	l_gc_mark(v_atom_while);
	l_gc_mark(v_atom_quote);
	l_gc_mark(v_atom_lambda);
	l_gc_mark(v_atom_nil);
	l_gc_mark(v_atom_true);
	l_gc_mark(v_list_nil);
	l_gc_mark_env(l_env_root);
	l_gc_mark_env(e);
	l_gc_sweep();
}

void l_gc_mark_env(l_env *e) {
	l_env_val *ptr = e->first;
	while (1) {
		if (ptr == NULL) break;
		l_gc_mark(ptr->val);

//		if (ptr->val->type == LAMBDA && ptr->val->env)
//			l_gc_mark_env(ptr->val->env);

		if (ptr->next == NULL) break;
		ptr = ptr->next;
	}
}

void l_gc_mark(l_value *v) {

	if (v == NULL || v->marked) return;
	v->marked = true;

	if (v->type == LIST || v->type == LAMBDA) {
		l_gc_mark(v->car);
		l_gc_mark(v->cdr);
	}

}

void l_gc_sweep(void) {

	l_obj_val *ptr = l_objs->first;
	l_obj_val *pptr = NULL;

	int i = 0;
	int im = 0;
	
	while (1) {

		if (ptr == NULL || ptr->val == NULL) break;

		if (ptr->val->marked) {
			ptr->val->marked = 0;
			im++;
		} else {
			l_obj_free(ptr, pptr);
			ptr = pptr;
		}

		if (ptr == NULL || ptr->next == NULL) break;
		pptr = ptr;
		ptr = ptr->next;
		i++;
	}

}

// OBJECT MEMORY MANAGEMENT

void l_obj_init(void) {
	l_objs =  (l_obj *)malloc(sizeof(l_obj));
	l_objs->first = NULL;
	l_objs->count = 0;
}

l_value *l_obj_alloc(void) {

	l_value *v = (l_value *)malloc(sizeof(l_value));
	l_obj_val *ov = (l_obj_val *)malloc(sizeof(l_obj_val));

	v->marked = false;

	ov->val = v;
	ov->next = l_objs->first;

	l_objs->first = ov;
	l_objs->count += 1;

	return v;

}

void l_obj_free(l_obj_val *ov, l_obj_val *pov) {

	if (ov->val->type == ATOM || ov->val->type == STR)
		free(ov->val->str);

	free(ov->val);

	if (!pov)
		l_objs->first = ov->next;
	else
		pov->next = ov->next;

	free(ov);

	l_objs->count -= 1;
}

// TYPES

l_value *v_atom(char *s) {
	l_value *atom = l_obj_alloc();
	atom->type = ATOM;
	atom->str = (char *)calloc(1, strlen(s) + 1);
	strncpy(atom->str, s, strlen(s));
	return atom;
}

l_value *v_num(double n) {
	l_value *num = l_obj_alloc();
	num->type = NUM;
	num->val = n;
	return num;
}

l_value *v_num_from_str(char *s) {
	double x;
//	sscanf(s, "%Lf", &x);
//	x = strtof(s, NULL);
	x = strtod(s, NULL);
//	x = atoi(s);
	return v_num(x);
}

l_value *v_str(char *s) {
	l_value *str = l_obj_alloc();
	str->type = STR;
	str->str = s;
	return str;
}

l_value *v_list(l_value *car, l_value *cdr) {
	l_value *list = l_obj_alloc();
	list->type = LIST;
	list->car = car;	
	list->cdr = cdr;
	return list;	
}

l_value *v_fun(void *fun) {
	l_value *f = l_obj_alloc();
	f->type = FUN;
	f->fun = fun;
	return f;
}

// (lambda (x y z ...) (fun))
l_value *v_lambda(l_value *lambda, l_env *e) {

	//printf("\nNEW LAMBDA: "); l_dump_nl(lambda);

	l_value *l = l_obj_alloc();
	l->type = LAMBDA;
	l->car = lambda;	
	l->cdr = NIL;
	l->env = e;

	return l;
}

// OPERATORS

l_value *op_read(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	return l_read(x->str);
}

l_value *op_eval(l_value *args, l_env *e) {
	return l_eval(l_eval(CAR(args), e), e);
}

l_value *op_quote(l_value *args, l_env *e) {
	return CAR(args);
}

l_value *op_atom(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	if (x->type == LIST && l_eq(x->car, NIL)) return TRUE;
	if (x->type == ATOM) return TRUE; else return FALSE;
	return FALSE;
}

l_value *op_num(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	if (x->type == NUM) return TRUE; else return FALSE;
	return FALSE;
}

l_value *op_str(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	if (x->type == STR) return TRUE; else return FALSE;
	return FALSE;
}

l_value *op_pair(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	if (x->type == LIST) return TRUE; else return FALSE;
	return FALSE;
}

// EQUALITY

l_value *op_eq(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	l_value *y = l_eval(CAR(CDR(args)), e);
	if (l_eq(x, y)) return TRUE; else return FALSE;
}

l_value *op_neq(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	l_value *y = l_eval(CAR(CDR(args)), e);
	if (!l_eq(x, y)) return TRUE; else return FALSE;
}

l_value *op_lt(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	l_value *y = l_eval(CAR(CDR(args)), e);
	if (x->type != NUM || y->type != NUM)
		l_log(L_PANIC, "lt expects a number");
	if (x->val < y->val) return TRUE; else return FALSE;
}

l_value *op_lte(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	l_value *y = l_eval(CAR(CDR(args)), e);
	if (x->type != NUM || y->type != NUM)
		l_log(L_PANIC, "lte expects a number");
	if (x->val <= y->val) return TRUE; else return FALSE;
}

l_value *op_gt(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	l_value *y = l_eval(CAR(CDR(args)), e);
	if (x->type != NUM || y->type != NUM)
		l_log(L_PANIC, "gt expects a number");
	if (x->val > y->val) return TRUE; else return FALSE;
}

l_value *op_gte(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	l_value *y = l_eval(CAR(CDR(args)), e);
	if (x->type != NUM || y->type != NUM)
		l_log(L_PANIC, "gte expects a number");
	if (x->val >= y->val) return TRUE; else return FALSE;
}

// LISTS

l_value *op_car(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	if (x->type != LIST)
		l_log(L_PANIC, "car expects a list");
	return CAR(x);
}

l_value *op_cdr(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	if (x->type != LIST)
		l_log(L_PANIC, "cdr expects a list");
	return CDR(x);
}

l_value *op_cons(l_value *args, l_env *e) {
	l_value *x = l_eval(CAR(args), e);
	l_value *y = l_eval(CAR(CDR(args)), e);
	if (y->type != LIST)
		l_log(L_PANIC, "second argument of cons must be a list");
	return CONS(x, y);
}

// CONDITIONS

l_value *op_cond(l_value *args, l_env *e) {

	l_value *p = CAR(args);
	l_value *x;
	l_value *rest = CDR(args);

	while (1) {

		if (l_eq(p, NIL)) break;

		x = l_eval(CAR(p), e);

		if (l_eq(x, TRUE))
			return l_eval(CAR(CDR(p)), e);

		p = CAR(rest);
		rest = CDR(rest);

	}

	return NIL;

}

// (if expr then else)
l_value *op_if(l_value *args, l_env *e) {

	l_value *q;
	l_value *x = CAR(args);
	l_value *y = CAR(CDR(args));
	l_value *z = CAR(CDR(CDR(args)));

	q = l_eval(x, e);

	if (l_eq(q, TRUE))
		return l_eval(y, e);

	if (z)
		return l_eval(z, e);

	return NIL;

}

// (let ((a 'b) (c 'd)) expr) 
l_value *op_let(l_value *args, l_env *e) {

	l_env *le = l_env_new();
	le->parent = e;
	
	l_value *pvs = CAR(args);
	l_value *fun = CAR(CDR(args));

	l_value *pvp = CAR(CAR(pvs));
	l_value *pva = CAR(CDR(CAR(pvs)));
	l_value *x;

	l_value *pvr = CDR(pvs);

	while (1) {

		if (l_eq(pvp, NIL)) break;
		if (l_eq(pva, NIL)) break;

		x = l_eval(pva, le);
		l_env_set_local(le, pvp->str, x);

		if (l_eq(pvr, NIL)) break;

		pvp = CAR(CAR(pvr));
		pva = CAR(CDR(CAR(pvr)));
		pvr = CDR(pvr);

	}

	//printf("let eval: "); l_dump_nl(fun);

	return l_eval(fun, le);

}

// (set! name val)
l_value *op_set(l_value *args, l_env *e) {
	l_value *x = CAR(args);
	l_value *y = CAR(CDR(args));
	l_env_set(e, x->str, l_eval(y, e));
	return TRUE;
}

// (defun name (arg1 arg2 ...) (fun))
l_value *op_defun(l_value *args, l_env *e) {
	l_value *x = CAR(args);
	l_value *y = CAR(CDR(args));
	l_value *z = CDR(CDR(args));
	l_value *l = CONS(v_atom_lambda, CONS(y, CONS(CAR(z), NIL)));
	l_env_set(e, x->str, l_eval(l, e));
	return TRUE;
}

// (define (name arg1 arg2 ...) (fun))
// (define name val)
l_value *op_define(l_value *args, l_env *e) {

	l_value *x, *y, *z, *l;
	l_value *q = CAR(args);

	if (q->type == LIST) {
		x = CAR(CAR(args));
		y = CDR(CAR(args));
		z = CDR(args);
		l = CONS(v_atom_lambda, CONS(y, CONS(CAR(z), NIL)));
	}
	else if (q->type == ATOM) {
		x = CAR(args);
		l = CAR(CDR(args));
	}
	else {
		return FALSE;
	}

	l_env_set(e, x->str, l_eval(l, e));
	return TRUE;
}

// (begin expr1 expr2 ...)
l_value *op_begin(l_value *args, l_env *e) {

	l_value *p = CAR(args);
	l_value *x = NIL;
	l_value *rest = CDR(args);

	while (1) {

		if (l_eq(p, NIL)) break;

		x = l_eval(p, e);

		if (l_eq(rest, NIL)) break;

		p = CAR(rest);
		rest = CDR(rest);

	}

	return x;
}

// (list a b c ...)
l_value *op_list(l_value *args, l_env *e) {

	l_value *list = CONS(NIL, NIL);
	l_value *root = list;
	l_value *x;
	l_value *p = CAR(args);
	l_value *rest = CDR(args);

	while (1) {

		if (p == NULL || l_eq(p, NIL)) break;

		x = l_eval(p, e);

		if (l_eq(list->car, NIL)) {
			list->car = x;
		} else {
			list->cdr = CONS(x, NIL);
			list = list->cdr;
		}

		if (l_eq(rest, NIL)) break;

		p = CAR(rest);
		rest = CDR(rest);

	}

	return root;

};

l_value *op_dump(l_value *args, l_env *e) {
	l_env_dump(e);
	return TRUE;
}

l_value *op_load(l_value *args, l_env *e) {
	l_value *x = CAR(args);
	l_load(x->str, e);
	return TRUE;
}

l_value *op_pn(l_value *args, l_env *e) {

	if (l_eq(args, NIL)) {
		printf("\n");
		return TRUE;
	}

	l_value *x = l_eval(CAR(args), e);

	if (x->type == STR)
		printf("%s\n", x->str);
	else
		l_dump_nl(x);

	return TRUE;
}

l_value *op_pp(l_value *args, l_env *e) {

	l_value *x = l_eval(CAR(args), e);

	if (x->type == STR)
		printf("%s", x->str);
	else
		l_dump(x);

	fflush(stdout);

	return TRUE;

}

l_value *op_gc(l_value *args, l_env *e) {
	printf("pre gc objects: %i\n", l_objs->count);
	l_gc(e);
	printf("post gc objects: %i\n", l_objs->count);
	return TRUE;
}

l_value *op_exit(l_value *args, l_env *e) {
	exit(0);
}

// STRINGS

// (str->list "abc") -> '(a b c)
l_value *op_str_to_list(l_value *args, l_env *e) {
	l_value *list = CONS(NIL, NIL);
	l_value *root = list;
	l_value *q = CAR(args);
	l_value *x;

	x = l_eval(q, e);

	char *p = x->str;
	char c[2];
	c[1] = 0;
	while (1) {
		if (*p == 0) break;
		c[0] = *p++;
		if (l_eq(list->car, NIL)) {
			list->car = v_atom(c);
		} else {
			list->cdr = CONS(v_atom(c), NIL);
			list = list->cdr;
		}
	}
	return root;
}

// (list->str '(a b c)) -> "abc"
l_value *op_list_to_str(l_value *args, l_env *e) {

	char *buf = (char *)calloc(1, MAX_STR_LEN);
	char *bp = buf;
	char *sptr;
	char cbuf[2];

	l_value *x;
	l_value *larg = CAR(args);

	x = l_eval(larg, e);

	if (x->type != LIST) {
		l_log(L_ERROR, "list->str requires a list");
		return NIL;
	}

	l_value *p = CAR(x);
	l_value *rest = CDR(x);

	int sl = 0;
	int al = 0;

	while (1) {

		if (p == NULL || l_eq(p, NIL)) break;

		if (p->type != ATOM && p->type != STR && p->type != NUM) {
			l_log(L_PANIC, "list->str requires a list of atoms or strs or nums");
			break;
		}

		if (p->type == NUM) {
			sptr = cbuf;
			unsigned char c = (unsigned char)p->val;
			cbuf[0] = c;
			cbuf[1] = c;
			al = 1;
		} else {
			sptr = p->str;
			al = strlen(p->str);
		}

		if (sl + al + 1 > MAX_STR_LEN) {
			l_log(L_ERROR, "string overflow");
			break;
		}

		strncpy(bp, sptr, al);

		bp += al;
		sl += al;

		if (l_eq(rest, NIL)) break;

		p = CAR(rest);
		rest = CDR(rest);

	}

	return v_str(buf);

}

l_value *op_num_to_str(l_value *args, l_env *e) {

	char *buf = (char *)calloc(1, MAX_STR_LEN);

	l_value *p = CAR(args);
	l_value *x;

	x = l_eval(p, e);

	sprintf(buf, "%f", x->val);

	return v_str(buf);

}

l_value *op_file_to_str(l_value *args, l_env *e) {

	l_value *p = CAR(args);
	l_value *x;

	x = l_eval(p, e);

	FILE *fp = fopen(x->str, "r");
	fseek(fp, 0L, SEEK_END);

	size_t size = ftell(fp);
	rewind(fp);

	char *buf = (char *)calloc(1, size + 1);

	fread(buf, size, 1, fp);

	return v_str(buf);

}

// ARITHMETIC

l_value *op_arith(l_value *args, l_env *e, l_arith_ops op) {

	l_value *p = CAR(args);
	l_value *x;
	l_value *rest = CDR(args);

	if (p == NULL) return v_num(0);

	double r = 0;

	if (!l_eq(rest, NIL)) {
		x = l_eval(p, e);
		r = x->val;
		p = CAR(rest);
		rest = CDR(rest);
	}

	while (1) {

		if (l_eq(p, NIL)) break;

		x = l_eval(p, e);

		switch (op) {
			case L_ADD: r += x->val; break;
			case L_SUB: r -= x->val; break;
			case L_MUL: r *= x->val; break;
			case L_DIV: r /= x->val; break;
			case L_MOD: r = fmod(r, x->val); break;
			default: break;
		}

		if (l_eq(rest, NIL)) break;

		p = CAR(rest);
		rest = CDR(rest);

	}

	return v_num(r);

}

l_value *op_add(l_value *args, l_env *e) { return op_arith(args, e, L_ADD); }
l_value *op_sub(l_value *args, l_env *e) { return op_arith(args, e, L_SUB); }
l_value *op_mul(l_value *args, l_env *e) { return op_arith(args, e, L_MUL); }
l_value *op_div(l_value *args, l_env *e) { return op_arith(args, e, L_DIV); }
l_value *op_mod(l_value *args, l_env *e) { return op_arith(args, e, L_MOD); }

l_value *op_time(l_value *args, l_env *e) {
#ifdef LIX
	return v_num(reg_rtc);
#else
	return v_num(time(NULL));
#endif
}

// PARSER

char *l_read_ptr;

l_value *l_read(const char *s) {

	l_read_ptr = (char *)s;
	bool quote_flag = false;

	l_tok *t;
	while ((t = l_token(l_read_ptr)) != NULL) {

		l_read_ptr = t->next;

		if (t->type == TQUOTE) {
			quote_flag = true;
			continue;
		}

		if (t->type == TLPAR) {
			if (quote_flag)
				return CONS(v_atom_quote, CONS(l_read_list(), NIL));
			else
				return l_read_list();
		}

		if (t->type == TATOM) {
			if (quote_flag)
				return CONS(v_atom_quote, CONS(v_atom(t->str), NIL));
			else
				return v_atom(t->str);
		}

		if (t->type == TNUM) {
			return v_num_from_str(t->str);
		}

		if (t->type == TSTR) {
			return v_str(t->str);
		}

	}

	return NIL;

}

l_value *l_read_list(void) {

	l_tok *t;
	l_value *p = CONS(NIL, NIL);
	l_value *root = p;

	l_value *item = NIL;
	bool quote_flag = false;

	while ((t = l_token(l_read_ptr)) != NULL) {

		l_read_ptr = t->next;

		if (t->type == TQUOTE) {
			quote_flag = true;
			continue;
		}

		if (t->type == TLPAR) {
			if (quote_flag) {
				item = CONS(v_atom_quote, CONS(l_read_list(), NIL));
				quote_flag = false;
			}
			else {
				item = l_read_list();
			}
		}

		if (t->type == TRPAR) {
			return root;
		}

		if (t->type == TATOM) {
			if (quote_flag) {
				item = CONS(v_atom_quote, CONS(v_atom(t->str), NIL));
				quote_flag = false;
			}
			else {
				item = v_atom(t->str);
			}
		}

		if (t->type == TNUM) {
			item = v_num_from_str(t->str);
		}

		if (t->type == TSTR) {
			item = v_str(t->str);
		}

		if (l_eq(p->car, NIL)) {
			p->car = item;
		} else {
			p->cdr = CONS(item, NIL);
			p = p->cdr;
		}

	}	

	return v_list_nil;

}

l_tok *l_token(char *s) {

	l_tok *t = (l_tok *)malloc(sizeof(l_tok));
	char *tok = (char *)calloc(1, MAX_STR_LEN);

	int toklen = 0;
	int toktype = TATOM;
	bool neg = false;

	while (*s != 0) {

		if (*s == ';') {
			toktype = TCOMMENT;
		}

		if (*s == '\n' && toktype == TCOMMENT) {
			toktype = TATOM;
			continue;
		}

		if (toktype == TCOMMENT) {
			s++;
			continue;
		}

		if (*s == ')' && !toklen && toktype != TSTR) {
			t->type = TRPAR;
			t->next = s + 1;
			return t;
		}

		if (*s == '\'' && (toktype != TSTR && toktype != TCOMMENT)) {
			t->type = TQUOTE;
			t->next = s + 1;
			return t;
		}

		if (*s == '"') {
			toktype = TSTR;
			s += 1;
			if (toklen) {
				t->type = TSTR;
				t->str = tok;
				t->next = s;
				return t;
			}
			continue;
		}

		if (*s == '(' && toktype != TSTR) {
			t->type = TLPAR;
			t->next = s + 1;
			return t;
		}
		else if ((isspace(*s) || *s == ')') && toktype != TSTR) {
			if (toklen) {
				if (neg && toklen == 1)
					t->type = TATOM;
				else
					t->type = toktype;

				t->str = tok;
				t->next = s;
				return t;
			}
		}
		else {
			if (!toklen && (isdigit(*s) || *s == '.' || *s == '-')) {
				if (*s == '-') neg = true;
				toktype = TNUM;
			}
			tok[toklen++] = *s;
		}

		s++;

	}

	return NULL;

}

// EVAL

l_value *l_eval(l_value *x, l_env *e) {

	EVAL:

	if (x->type == LIST) {

		l_value *op = CAR(x);
		l_value *args = CDR(x);

		if (op->type == LIST) {
			return l_apply(l_eval(op, e), args, e);
		}

		if (op->type == LAMBDA) {
			return l_apply(CAR(op), args, e);
		}

		if (op->type == ATOM && l_eq(op, v_atom_lambda)) {
			return v_lambda(args, e);
		}

		if (op->type == ATOM) {

			if (l_eq(op, v_atom_while)) {
				l_value *t = CAR(args);
				if (l_eq(l_eval(t, e), TRUE)) {
					l_eval(CAR(CDR(args)), e);
					goto EVAL;
				} else {
					return TRUE;
				}
			}

			l_value *v = l_env_find(e, op->str);

			if (l_eq(v, NIL)) return NIL;

			if (v->type == LIST || v->type == ATOM) {
				return l_eval(CONS(v, args), e);
			}

			if (v->type == LAMBDA) {
				return l_apply(v, args, e);
			}

			if (v->type == FUN) {
				return (l_value *)v->fun(args, e);
			}

		}

	}

	if (x->type == ATOM) {
		return l_env_find(e, x->str);
	}

	if (x->type == NUM || x->type == STR || x->type == LAMBDA) {
		return x;
	}

	return NIL;

}

l_value *l_apply(l_value *lambda, l_value *args, l_env *e) {

	l_env *le = l_env_new();
	le->parent = lambda->env;

	l_value *params = CAR(CAR(lambda));
	l_value *fun = CAR(CDR(CAR(lambda)));

	if (l_eq(args, NIL)) {
		fun = CAR(CAR(lambda));
		return l_eval(fun, le);
	}

	l_value *pa = CAR(args);
	l_value *pp = CAR(params);
	l_value *x;
	l_value *par = CDR(args);
	l_value *ppr = CDR(params);

	while (1) {

		if (pa == NULL || l_eq(pa, NIL)) break;
		if (pp == NULL || l_eq(pp, NIL)) break;

		x = l_eval(pa, e);

		l_env_set_local(le, pp->str, x);

		if (l_eq(par, NIL)) break;
		if (l_eq(ppr, NIL)) break;

		pa = CAR(par);
		pp = CAR(ppr);
		par = CDR(par);
		ppr = CDR(ppr);

	}

	l_value *ret = l_eval(fun, le);
	return ret;

}

// REPL (read eval print loop)
void l_repl_simple(l_env *env) {

	char *buf = (char *)calloc(1, MAX_STR_LEN);

	while (1) {

		printf("ll> ");
		fflush(stdout);
		bzero(buf, MAX_STR_LEN);
#ifdef LIX
		readline(buf, MAX_STR_LEN - 1);
		printf("\n");
#else
		fgets(buf, MAX_STR_LEN - 1, stdin);
#endif

		if (strncmp(buf, "\n", 1) == 0) continue;

		l_value *stmt = l_read(buf);
		if (stmt == NULL) {
			l_log(L_ERROR, "parse error");
			continue;
		}
	//	l_dump_nl(stmt);
	//	printf("==\n");	
		l_dump_nl(l_eval(stmt, env));

	}

};

void l_ep(char *buf) {

	if (strncmp(buf, "\n", 1) == 0) return;

	l_value *stmt = l_read(buf);
	if (stmt == NULL)
		l_log(L_ERROR, "parse error");
	else
		l_dump_nl(l_eval(stmt, l_env_root));

};

void l_load(char *filename, l_env *e) {

	printf("[load:%s] ", filename);

#ifdef LIX
	uint32_t size = fs_size(filename);
	if (size == 0) {
		fprintf(stderr, "file not found: %s\n", filename);
		return;
	}
	char *fbuf = fs_mallocfile(filename);
	if (fbuf == NULL) {
		fprintf(stderr, "unable to load file: %s\n", filename);
		return;
	}
	const char *begin = "(begin ";
	char *buf = calloc(1, size + 1 + strlen(begin) + 1);
	strncpy(buf, begin, strlen(begin) + 1);
	memcpy(buf + strlen(begin), fbuf, size);
	buf[size + strlen(begin)] = ')';
	l_value *stmt = l_read(buf);
	PUSH(l_gc_stack, stmt);
	l_dump_nl(l_eval(stmt, e));
	POP(l_gc_stack);
	free(buf);
#else
	FILE *fp;
	fp = fopen(filename, "r");
	if (!fp) {
		fprintf(stderr, "file not found: %s\n", filename);
		exit(EXIT_FAILURE);
	}
	fseek(fp, 0L, SEEK_END);
	long size = ftell(fp);
	rewind(fp);
	const char *begin = "(begin ";
	char *buf = calloc(1, size + 1 + strlen(begin) + 1);
	strncpy(buf, begin, strlen(begin) + 1);
	fread(buf + strlen(begin), size, 1, fp);
	buf[size + strlen(begin)] = ')';
	fclose(fp);
	l_value *stmt = l_read(buf);
	PUSH(l_gc_stack, stmt);
	l_dump_nl(l_eval(stmt, e));
	POP(l_gc_stack);
	free(buf);
#endif

}

// DEFAULT ENVIRONMENT

l_env *l_env_std(void) {
	l_env *env = l_env_new();
	l_env_set(env, "read", v_fun(&op_read));
	l_env_set(env, "eval", v_fun(&op_eval));
	l_env_set(env, "quote", v_fun(&op_quote));
	l_env_set(env, "atom?", v_fun(&op_atom));
	l_env_set(env, "num?", v_fun(&op_num));
	l_env_set(env, "str?", v_fun(&op_str));
	l_env_set(env, "pair?", v_fun(&op_pair));
	l_env_set(env, "car", v_fun(&op_car));
	l_env_set(env, "cdr", v_fun(&op_cdr));
	l_env_set(env, "cons", v_fun(&op_cons));
	l_env_set(env, "eq", v_fun(&op_eq));
	l_env_set(env, "=", v_fun(&op_eq));
	l_env_set(env, "!=", v_fun(&op_neq));
	l_env_set(env, "<", v_fun(&op_lt));
	l_env_set(env, "<=", v_fun(&op_lte));
	l_env_set(env, ">", v_fun(&op_gt));
	l_env_set(env, ">=", v_fun(&op_gte));
	l_env_set(env, "cond", v_fun(&op_cond));
	l_env_set(env, "if", v_fun(&op_if));
	l_env_set(env, "let", v_fun(&op_let));
	l_env_set(env, "set!", v_fun(&op_set));
	l_env_set(env, "defun", v_fun(&op_defun));
	l_env_set(env, "define", v_fun(&op_define));
	l_env_set(env, "begin", v_fun(&op_begin));
	l_env_set(env, "list", v_fun(&op_list));
	l_env_set(env, "dump", v_fun(&op_dump));
	l_env_set(env, "load", v_fun(&op_load));
	l_env_set(env, "pp", v_fun(&op_pp));
	l_env_set(env, "pn", v_fun(&op_pn));
	l_env_set(env, "gc", v_fun(&op_gc));
	l_env_set(env, "exit", v_fun(&op_exit));
	l_env_set(env, "str->list", v_fun(&op_str_to_list));
	l_env_set(env, "list->str", v_fun(&op_list_to_str));
	l_env_set(env, "num->str", v_fun(&op_num_to_str));
	l_env_set(env, "file->str", v_fun(&op_file_to_str));
	l_env_set(env, "+", v_fun(&op_add));
	l_env_set(env, "-", v_fun(&op_sub));
	l_env_set(env, "*", v_fun(&op_mul));
	l_env_set(env, "/", v_fun(&op_div));
	l_env_set(env, "%", v_fun(&op_mod));
	l_env_set(env, "time", v_fun(&op_time));
	return env;
};

void l_init(void) {
	l_obj_init();
	v_atom_true = v_atom("t");
	v_atom_nil = v_atom("nil");
	v_atom_lambda = v_atom("lambda");
	v_atom_quote = v_atom("quote");
	v_atom_while = v_atom("while");
	v_list_nil = v_list(v_atom_nil, v_atom_nil);
	l_gc_stack = v_atom_nil;
#ifndef LIX
	srand(time(NULL)); 
#endif
}

#ifdef LIX
void l_init_lix(bool stdlib) {

	l_init();
	l_env_root = l_env_std();
	if (stdlib) {
		l_value *stmt = l_read((const char *)ll_stdlib_l);
		PUSH(l_gc_stack, stmt);
		l_eval(stmt, l_env_root);
	}

}
#endif

#ifndef LIX
int main(int argc, char **argv) {

	l_init();
	l_env_root = l_env_std();
	l_repl_simple(l_env_root);

}
#endif
