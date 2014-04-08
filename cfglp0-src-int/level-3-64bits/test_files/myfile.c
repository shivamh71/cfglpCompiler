main()
{
	int a;
	int b = 2;
	{
		int c;
		int d = 2;
		if (c==d) {
			d = d;
		}
		else {
			a = b;
		}
	}
	return;
}