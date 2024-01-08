# Pop!_OS Config Via Ansible

Inspiration taken from Learn Linux TV Youtube video. I'm a new Linux user and really have come to like using Pop!_OS. With my new laptop on the way, I was thinking of all the tweaks that I wanted to make. During my research I came across the video and thought it would be the perfect project to learn some new skills. This repository will sort of a journal of my journey into the world of Ansible!

## Ansible Pull Command
```bash
sudo ansible-pull -U https://github.com/ciswindell/ansible_popos.git
```

## GNOME Settings Trick

Here's a great way to figure out what tasks to setup in your GNOME settings
```bash
dconf dump / > before.txt
```
```bash
dconf dump / > after.txt
```
```bash
diff before.txt after.txt
```

## Todo

- [ ] Setup Windows VM task
- [ ] Default Package List
