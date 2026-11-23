# Wizard Academia card layer

`CardCatalog.lua` contains only plain card data. Generation, acquisition,
collection navigation, and day advancement remain gameplay systems in this
directory. `CardUiUpdateSystem` owns card-screen input and emits requests;
rendering remains under `src/game/ui/`. No LOVE objects may enter the persistent
game session.
