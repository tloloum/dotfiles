return {
	"folke/persistence.nvim",
	event = "BufReadPre",
	opts = {
		-- Ne sauvegarde que si au moins 1 fichier est ouvert : évite
		-- d'écraser une session en quittant depuis le dashboard
		need = 1,
		branch = true, -- une session distincte par branche git
	},
}
