.SUFFIXES:
.SUFFIXES: .el .elc
.el.elc : 
	$(emacs) -nw -batch -q -l bytecomp -f batch-byte-compile $*.el

emacs = /usr/local/emacs

elc-files = modes.elc subprocess.elc subprocess-lisp.elc\
	    subprocess-filec.elc subprocess-ring.elc\
	    lisp-indent.elc aux.elc

all:	depend doc.n

depend: ${elc-files}

doc.n:	list.n ${elc-files}
	$(emacs) -batch -q -l doc.el

pr = enscript -Plw -h -2r

print:; ${pr} Makefile *.el

e = /usr/emacs

tags:
	(cd /usr/emacs; etags ${e}/lisp/fi/*.el ${e}/lisp/local/*.el\
		${e}/lisp/*.el ${e}/src/*.[hc])

backup:
	rdist -Rc . binky:emacs.save/fi
