;;; term-keys-kitty.el --- term-keys support for kitty

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program; see the file COPYING.  If not, write to
;; the Free Software Foundation, Inc., 59 Temple Place - Suite 330,
;; Boston, MA 02111-1307, USA.

;;; Commentary:

;; This file contains supplementary code for aiding in the
;; configuration of the kitty terminal emulator to interoperate with
;; the term-keys package.

;; For more information, please see the accompanying README.md file.

;;; Code:


(require 'term-keys)


(defgroup term-keys/glfw nil
  "`term-keys' options for GLFW-based terminal emulators."
  :group 'term-keys)

(define-widget 'term-keys/glfw-modifier 'lazy
  "Choice for GLFW key modifier state flags."
  :type '(choice (const "SHIFT")
		 (const "CONTROL")
		 (const "ALT")
		 (const "SUPER")
		 (const "CAPS_LOCK")
		 (const "NUM_LOCK")
		 (const :tag "(none)" nil)))


(defcustom term-keys/glfw-modifier-map ["SHIFT" "CONTROL" "ALT" "SUPER" nil nil]
  "Map of GLFW modifier state flags to Emacs modifiers.

This should be a vector of 6 elements, with each element being a
string indicating the name of the GLFW modifier name (sans the
\"GLFW_MOD_\" prefix) corresponding to the Emacs modifiers Shift,
Control, Meta, Super, Hyper and Alt respectively.  nil indicates
that there is no mapping for this modifier.

https://www.glfw.org/docs/latest/group__mods.html"
  :type '(vector
	  (term-keys/glfw-modifier :tag "Shift")
	  (term-keys/glfw-modifier :tag "Control")
	  (term-keys/glfw-modifier :tag "Meta")
	  (term-keys/glfw-modifier :tag "Super")
	  (term-keys/glfw-modifier :tag "Hyper")
	  (term-keys/glfw-modifier :tag "Alt"))
  :group 'term-keys/glfw)


(defun term-keys/glfw-mods-representable (mods)
  "Return non-nil if the given MODS vector is representable in GLFW."
  (cl-reduce (lambda (x y) (and x y)) ; all
	     (mapcar (lambda (n)
		       (or (not (elt mods n)) ; inactive modifier
			   (elt term-keys/glfw-modifier-map n))) ; mapped
		     (number-sequence 0 (1- (length mods)))))) ; 0..5


(defun term-keys/kitty-format-key (keymap mods)
  "Format key and modifiers in kitty syntax.

Returns the kitty key combination string corresponding to the
KEYMAP and modifier state MODS."
  (concat
   (cl-loop for modflag across mods
	    for index from 0
	    if modflag
	    concat
	    (concat
	     (elt term-keys/glfw-modifier-map index)
	     "+"))
   (elt keymap 7)))


(defun term-keys/kitty-conf ()
  "Construct kitty configuration (kitty.conf fragment).

This function returns, as a string, the kitty.conf map lines
necessary to configure kitty to encode term-keys key sequences,
according to the term-keys configuration."
  (apply #'concat
	 (term-keys/iterate-keys
	  (lambda (index keymap mods)
	    (format "map %-55s send_text all %s\n"
		    (term-keys/kitty-format-key keymap mods)
		    (mapconcat
		     (lambda (c) (format "\\x%02x" c))
		     (append
		      term-keys/prefix
		      (term-keys/encode-key index mods)
		      term-keys/suffix
		      nil)
		     ""))))))


(provide 'term-keys-kitty)
;;; term-keys-kitty.el ends here
