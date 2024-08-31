- penser à un system de notification/message global
- peut être bloquer la descente/montée d'une octave si pas atteignable plutôt que de clamp sur le min/max

# Test MM+

- [ ] voir si le rebind des touches fonctionne pour avoir les input de player 2 sur select


# Vue Pattern

- trouver une manière de set le speed de plusieurs sfx à la fois


# Playback

- play from current position / selection
- bonne gestion de preview de la note sans écrire dans la mémoire d'un sfx (remap pointeur)
- loop d'une section donnée ?

# Input handling

- mieux gérer les input avec modifier
    - si mod+v, si on lache mode avant v, ne devrait pas enclencher v tout seul

# Vue SFX

- params en plus
    - speed
    - son
        - noize
        - buzz
        - detune
        - reverb
        - dampen
- prévoir futur
    - mode wave
    - instrument custom

# More TODOS

- [ ] system de message / notification en bas
- [ ] mini map du pane actuel
- [X] meilleur gestion du hold_b+a pour delete pour éviter de recréer la note si on relache b en premier
- [ ] pattern editor multi selection
    - [ ] done but UX to improve
- [ ] special behaviour of effect 1 : the note should be visible even if the volume is at 0 as it affects the previous note
- [ ] playhead out of the grid when still playing as the out loop is more than 32
- [ ] il doit y avoir un moyen de copier tout un sfx, settings inclues, et de le paste sur un autre sfx
    - [ ] done but improve UX
- [X] si je sélectionne le volume de toutes les notes, est ce que si je change la valeur c'est sensé la changer pour tous, ou juste pour les notes actives ? J'aurais tendance à dire juste les notes actives



# Before 1.0 release

- se décider pour 6 ou 8 boutons
- 
- system de message
- écran d'intro qui vérifie qu'on a bien tous les boutons qu'il faut
- vue settings
- review UX de l'ensemble
- mini map
