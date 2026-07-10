return {
	-- Plugin officiel GitHub Copilot. Accepte la suggestion avec <Tab>
	-- par défaut (ghost-text grisé). N'interfère pas avec Entrée / nvim-cmp.
	"github/copilot.vim",
	cmd = "Copilot",       -- charge le plugin dès qu'on tape :Copilot ...
	event = "InsertEnter", -- ... et aussi dès qu'on entre en insertion

}
