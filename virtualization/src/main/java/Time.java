public class Time {
	public static void main(String[] args) throws Exception {
                long ftime = System.currentTimeMillis();
                long stime = Long.parseLong(args[0]);
		System.out.println(ftime - stime);
	}
}
